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
import gleam/otp/task
import gleam/result
import gleam/string
import gleam/uri
import gleam_galaxy/error.{type Error}
import gleam_galaxy/job/job_models
import gleam_galaxy/models.{type State}

// import pprint as pp
import shakespeare/actors/periodic.{Ms, start}
import wisp

/// Start Cron Job to Sync Hex Packages
pub fn start_sync(hex_key: String, tinybird_key: String) {
  wisp.log_info("Start Scheduler")

  io.println("\nLatest TS")

  let state =
    models.State(
      page: 1,
      last_updated_at: birl.utc_now(),
      hex_key: hex_key,
      tinybird_key: tinybird_key,
      current_time: birl.utc_now(),
    )

  // Periodic actor takes a function, and sync needs state. Run every 10hr to get 2x a day
  // 36_000_000
  let cron = fn() { sync_data(state) }
  start(do: cron, every: Ms(36_000_000))
}

/// Job that Syncs Hex Package Data
fn sync_data(state: State) -> Nil {
  let last_updated_at = case get_max_package_updated_at(state.tinybird_key) {
    Ok(t) -> t
    Error(_) ->
      birl.utc_now()
      |> birl.subtract(duration.years(5))
  }

  let state = models.State(..state, last_updated_at: last_updated_at)
  wisp.log_info("Start Cron Job at: " <> state.current_time |> birl.to_iso8601)

  // Sync Updates
  wisp.log_info("===== Sync Updates =====")
  // let _ = sync_updates(state)

  // Sync Downloads
  wisp.log_info("===== Sync Downloads =====")
  // let _ = sync_downloads(state)

  wisp.log_info(
    "Cron Job Completed at: " <> state.current_time |> birl.to_iso8601,
  )
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

  let init =
    birl.utc_now()
    |> birl.subtract(duration.years(5))

  let max_time = case list.first(max_update.data) {
    Ok(t) -> birl.parse(t.max_updated_at)
    Error(_) ->
      init
      |> Ok()
  }

  max_time
  |> result.unwrap(init)
  |> birl.subtract(duration.hours(8))
  |> Ok()
}

/// Sync Package Updates ==========================================================================
fn sync_updates(state: State) {
  use packages <- result.try(fetch_packages(state))
  io.println("LIST LENGTH:" <> int.to_string(list.length(packages)))

  use min_date <- result.try(min_timestamp(packages))
  let start = birl.utc_now()

  // 100 / chunk size = num_tasks
  let chunks = list.sized_chunk(packages, 20)
  // io.println("Chunk LENGTH:" <> int.to_string(list.length(chunks)))

  let handles =
    list.map(chunks, fn(chunk) {
      task.async(fn() {
        list.map(chunk, fn(pkg) {
          process.sleep(200)
          process_package(pkg, state)
        })
      })
    })

  let pkgs =
    list.fold(handles, [], fn(acc, handle) {
      let result = task.await(handle, 60_000)
      list.concat([result, acc])
    })

  io.println("pkgs LENGTH:" <> int.to_string(list.length(pkgs)))

  // io.debug(list.length(pkgs))
  io.println(
    "Run Time ----> " <> birl.legible_difference(birl.utc_now(), start),
  )
  process.sleep(60_000)

  // If min package updated at greater than or equal to max tb date
  // then keep looping as have not seen all packages
  let _ = case birl.compare(min_date, state.last_updated_at) {
    Gt | Eq -> {
      io.println(
        "Gt Eq"
        <> " Packages Date"
        <> birl.to_iso8601(min_date)
        <> " Min Date TB: "
        <> birl.to_iso8601(state.last_updated_at),
      )
      sync_updates(models.State(..state, page: state.page + 1))
    }
    Lt -> {
      io.println(
        "LT"
        <> " Packages Date"
        <> birl.to_iso8601(min_date)
        <> " Min Date TB: "
        <> birl.to_iso8601(state.last_updated_at),
      )
      Ok(Nil)
    }
  }

  Ok(Nil)
}

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
  io.println("Page: " <> int.to_string(state.page))
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
      io.println(package.name <> " - NO GLEAM RELEASES")
      Ok(state)
    }
    _ -> {
      io.println("UPDATE - " <> package.name)
      let _ = insert_updates(package, releases, state)
      Ok(state)
    }
  }
}

fn insert_updates(
  package: hexpm.Package,
  releases: List(hexpm.Release),
  state: State,
) {
  // io.println("CREATE JSON")
  let _ =
    create_package_json(package)
    |> insert_data_tb(state.tinybird_key, "packages")

  // io.println("CREATE RELEASES")
  create_release_json(package.name, releases)
  |> insert_data_tb(state.tinybird_key, "package_releases")
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

  case response.status > 299 {
    True ->
      io.print_error(
        "RELEASE REQUEST: "
        <> url.path
        <> " "
        <> release.version
        <> " "
        <> int.to_string(response.status)
        <> response.body,
      )
    _ -> Nil
  }

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

// Map over all releases, and create a ndjson string to be inserted which contains all releases
fn create_release_json(package_name: String, releases: List(hexpm.Release)) {
  list.fold(releases, "", fn(b, a) {
    b <> "\n" <> release_to_json(package_name, a)
  })
}

fn release_to_json(package_name: String, release: hexpm.Release) {
  let hex_updated_at =
    release.updated_at
    |> birl.to_iso8601()
    |> json.string()

  let hex_inserted_at =
    release.inserted_at
    |> birl.to_iso8601()
    |> json.string()

  let inserted_at =
    birl.utc_now()
    |> birl.to_iso8601()
    |> json.string()

  let x = {
    json.object([
      #("package_name", json.string(package_name)),
      #("release", json.string(release.version)),
      #("release_downloads", json.int(release.downloads)),
      #("url", json.string(release.url)),
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

// Insert Package

fn insert_data_tb(body: String, tinybird_key: String, table_name: String) {
  let _ =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_host("api.us-east.tinybird.co")
    |> request.set_path("/v0/events")
    |> request.prepend_header("Authorization", "Bearer " <> tinybird_key)
    |> request.set_query([#("name", table_name)])
    |> request.set_body(body)
    |> hackney.send
    |> result.map_error(error.HttpClientError)
  Ok(Nil)
}

// Sync Downloads =======================================================================

fn sync_downloads(state: State) {
  let packages = case get_list_gleam_packages(state) {
    Ok(packages) -> {
      { int.to_string(list.length(packages)) <> " Packages to Get Downloads" }
      |> io.println()
      packages
    }
    Error(_) -> []
  }

  let start = birl.utc_now()

  let chunk_size = list.length(packages) / 5
  let chunks = list.sized_chunk(packages, chunk_size)

  let handles =
    list.map(chunks, fn(chunk) {
      task.async(fn() {
        list.map(chunk, fn(pkg) {
          process.sleep(1000)
          io.println("Getting downloads - " <> pkg)
          fetch_package(pkg, state.hex_key)
        })
      })
    })

  let _ =
    list.fold(handles, [], fn(acc, handle) {
      let result = task.await(handle, 3_600_000)
      list.concat([result, acc])
    })
    |> list.fold("", fn(b, a) { b <> create_package_downloads(a) })
    |> insert_data_tb(state.tinybird_key, "package_daily_downloads")

  io.println(
    "Run Time ----> " <> birl.legible_difference(birl.utc_now(), start),
  )
}

fn get_list_gleam_packages(state: State) {
  use response <- result.try(
    request.new()
    |> request.set_host("api.us-east.tinybird.co")
    |> request.set_path("/v0/pipes/list_of_packages.csv")
    |> request.prepend_header("Authorization", "Bearer " <> state.tinybird_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  let packages =
    response.body
    |> string.split("\n")
    |> list.map(fn(x) { string.replace(in: x, each: "\"", with: "") })
    |> list.filter(fn(x) { string.length(x) > 0 })

  Ok(packages)
}

fn create_package_downloads(package: Result(hexpm.Package, Error)) {
  case package {
    Ok(package) -> {
      let downloads =
        package.downloads
        |> dict.get("day")
        |> result.unwrap(0)

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
          #("package_name", json.string(package.name)),
          #("date", date),
          #("downloads_yesterday", json.int(downloads)),
          #("inserted_at", inserted_at),
        ])
      }
      json.to_string(x) <> "\n"
    }
    Error(_) -> ""
  }
}
