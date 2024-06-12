import app/error.{type Error}
import app/job/job_models
import app/models.{type State}
import birl.{type Time}
import birl/duration
import gleam/dict
import gleam/dynamic
import gleam/erlang/process
import gleam/hackney
import gleam/hexpm.{type Package}
import gleam/http
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/order.{Eq, Gt, Lt}
import gleam/result
import gleam/uri
import pprint as pp
import shakespeare/actors/periodic.{Ms, start}
import wisp

/// Start Cron Job to Sync Hex Packages
pub fn start_sync(hex_key: String, tinybird_key: String) {
  wisp.log_info("Start Scheduler")

  let last_updated_at = case get_max_package_updated_at(tinybird_key) {
    Ok(t) -> t
    Error(_) ->
      birl.utc_now()
      |> birl.subtract(duration.years(5))
  }

  io.println("\nLatest TS")
  pp.debug(last_updated_at)

  let state =
    models.State(
      page: 1,
      last_updated_at: last_updated_at,
      hex_key: hex_key,
      tinybird_key: tinybird_key,
      current_time: birl.utc_now(),
    )

  // Periodic actor takes a function, and sync needs state. Run every ...
  let cron = fn() { sync_data(state) }
  start(do: cron, every: Ms(5000))
}

/// Job that Syncs Hex Package Data
fn sync_data(state: State) -> Nil {
  wisp.log_info("Start Cron Job at: " <> state.current_time |> birl.to_iso8601)

  // io.println("\nState")
  // pp.debug(state)

  // Sync Updates
  pp.debug(sync_updates(state))
  // Sync Downloads

  Nil
}

/// Get Max Package Updated At Returns max time from packages table minus 8 hours in case a job failed
pub fn get_max_package_updated_at(tinybird_key: String) {
  use response <- result.try(
    request.new()
    |> request.set_host("api.us-east.tinybird.co")
    |> request.set_path("/v0/pipes/max_updated_at.json")
    |> request.prepend_header("Authorization", "Bearer " <> tinybird_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  use max_update <- result.try(
    json.decode(response.body, using: job_models.decode_max_package_updated_at)
    |> result.map_error(error.JsonDecodeError),
  )

  let max_time = case list.first(max_update.data) {
    Ok(t) -> birl.parse(t.max_updated_at)
    Error(_) -> Ok(birl.utc_now())
  }

  max_time
  |> result.unwrap(birl.utc_now())
  |> birl.subtract(duration.hours(8))
  |> io.debug()
  |> Ok()
}

/// Sync Package Updates
fn sync_updates(state: State) {
  use packages <- result.try(fetch_packages(state))
  use min_date <- result.try(min_timestamp(packages))
  //pp.debug(packages)
  io.println("TESTING --------")
  list.each(packages, fn(a) {
    process.sleep(50)
    io.debug(a.name)
    process_package(a, state)
  })

  case birl.compare(min_date, state.last_updated_at) {
    Gt | Eq ->
      io.println(
        "Gt Eq"
        <> birl.to_iso8601(min_date)
        <> birl.to_iso8601(state.last_updated_at),
      )
    Lt -> io.println("Lt")
  }

  Ok(Nil)
}

// /// Sync Package Updates
// fn sync_downloads(state: State) {
//   todo
// }

fn min_timestamp(packages: List(hexpm.Package)) -> Result(Time, Error) {
  // Assume the packages are sorted desc
  let assert Ok(first) = list.first(packages)
  let assert Ok(last) = list.last(packages)
  case birl.compare(first.updated_at, last.updated_at) {
    Gt | Eq -> Nil
    Lt -> panic as "PACKAGES NOT SORTED CORRECTLY"
  }

  case list.last(packages) {
    Ok(last) -> last.updated_at
    Error(_) -> birl.from_unix(0)
  }
  |> Ok()
}

fn fetch_packages(state: State) -> Result(List(hexpm.Package), Error) {
  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages")
    |> request.set_query([
      #("sort", "updated_at"),
      #("page", int.to_string(state.page)),
    ])
    |> request.prepend_header("authorization", state.hex_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )
  use all_packages <- result.try(
    json.decode(response.body, using: dynamic.list(of: hexpm.decode_package))
    |> result.map_error(error.JsonDecodeError),
  )
  Ok(all_packages)
}

fn process_package(package: hexpm.Package, state: State) {
  use releases <- result.try(lookup_gleam_releases(package, state.hex_key))
  case releases {
    [] -> {
      io.print("NO GLEAM RELEASES")
      Ok(state)
    }
    _ -> {
      pp.debug(package.name)
      pp.debug(list.first(releases))
      insert_updates(package, releases, state)
      Ok(state)
    }
  }
}

fn insert_updates(
  package: hexpm.Package,
  releases: List(hexpm.Release),
  state: State,
) {
  io.println("CREATE JSON")
  create_package_json(package)
  |> insert_data_tb(state.tinybird_key, "packages")
}

fn lookup_gleam_releases(
  package: hexpm.Package,
  hex_key: String,
) -> Result(List(hexpm.Release), Error) {
  use releases <- result.try(
    list.try_map(package.releases, lookup_release(_, hex_key)),
  )
  releases
  |> list.filter(fn(release) {
    list.contains(release.meta.build_tools, "gleam")
  })
  |> Ok
}

fn lookup_release(
  release: hexpm.PackageRelease,
  hex_key: String,
) -> Result(hexpm.Release, Error) {
  let assert Ok(url) = uri.parse(release.url)

  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path(url.path)
    |> request.prepend_header("authorization", hex_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  json.decode(response.body, using: hexpm.decode_release)
  |> result.map_error(error.JsonDecodeError)
}

pub fn create_download_json(pkg: Package) {
  let downloads =
    pkg.downloads
    |> dict.get("day")
    |> result.unwrap(0)
    |> json.int()

  let date =
    birl.utc_now()
    |> birl.to_naive_date_string()
    |> json.string()

  let inserted_at =
    birl.utc_now()
    |> birl.to_iso8601()
    |> json.string()

  let x = {
    json.object([
      #("package_name", json.string(pkg.name)),
      #("downloads_yesterday", downloads),
      #("date", date),
      #("inserted_at", inserted_at),
    ])
  }
  json.to_string(x)
}

pub fn create_package_json(pkg: Package) {
  let downloads =
    pkg.downloads
    |> dict.get("all")
    |> result.unwrap(0)
    |> json.int()

  let repo_url =
    pkg.meta.links
    |> dict.get("Repository")
    |> result.unwrap("")
    |> json.string()

  let hex_updated_at =
    pkg.updated_at
    |> birl.to_iso8601()
    |> json.string()

  let hex_inserted_at =
    pkg.inserted_at
    |> birl.to_iso8601()
    |> json.string()

  let inserted_at =
    birl.utc_now()
    |> birl.to_iso8601()
    |> json.string()

  let x = {
    json.object([
      #("package_name", json.string(pkg.name)),
      #("hex_url", json.string(option.unwrap(pkg.html_url, ""))),
      #("description", json.string(option.unwrap(pkg.meta.description, ""))),
      #("licenses", json.array(pkg.meta.licenses, of: json.string)),
      #("repository_url", repo_url),
      #("owners", json.array([], of: json.string)),
      #("downloads_all_time", downloads),
      #("hex_updated_at", hex_updated_at),
      #("hex_inserted_at", hex_inserted_at),
      #("inserted_at", inserted_at),
    ])
  }
  json.to_string(x)
}

pub fn fetch_package(package_name: String, hex_key: String) {
  use response <- result.try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path("/api/packages/" <> package_name)
    |> request.prepend_header("authorization", hex_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  use package <- result.try(
    json.decode(response.body, using: hexpm.decode_package)
    |> result.map_error(error.JsonDecodeError),
  )

  Ok(package)
}

pub fn get_gleam_packages(tinybird_key: String) {
  use response <- result.try(
    request.new()
    |> request.set_host("api.us-east.tinybird.co")
    |> request.set_path("/v0/pipes/list_of_packages.json")
    |> request.prepend_header("Authorization", "Bearer " <> tinybird_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  use package_list <- result.try(
    json.decode(response.body, using: job_models.decode_gleam_packages)
    |> result.map_error(error.JsonDecodeError),
  )

  package_list.data
  |> list.map(fn(x) { x.package })
  |> Ok()
}

// Insert Package

pub fn insert_data_tb(body: String, tinybird_key: String, table_name: String) {
  use response <- result.try(
    request.new()
    |> request.set_method(http.Post)
    |> request.set_host("api.us-east.tinybird.co")
    |> request.set_path("/v0/events")
    |> request.prepend_header("Authorization", "Bearer " <> tinybird_key)
    |> request.set_query([#("name", table_name)])
    |> request.set_body(body)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )
  io.debug(response)
  Ok(Nil)
}
