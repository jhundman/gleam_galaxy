import app/error.{type Error}
import app/job/job_models
import app/models.{type State}
import birl.{type Time}
import birl/duration
import gleam/dict
import gleam/dynamic
import gleam/hackney
import gleam/hexpm.{type Package}
import gleam/http
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option
import gleam/order
import gleam/result
import pprint as pp
import shakespeare/actors/periodic.{Ms, start}
import wisp

/// Start Cron Job to Sync Hex Packages
pub fn start_job(hex_key: String, tinybird_key: String) {
  wisp.log_info("Start Scheduler")

  let latest_ts = get_max_package_updated_at(tinybird_key)

  let latest_ts = case latest_ts {
    Ok(t) -> t
    Error(_) ->
      birl.utc_now()
      |> birl.subtract(duration.years(5))
  }

  io.println("\nLatest TS")
  pp.debug(latest_ts)

  let s =
    models.State(
      page: 1,
      newest: latest_ts,
      hex_key: hex_key,
      tinybird_key: tinybird_key,
      updated_at: birl.utc_now(),
    )

  let cron = fn() { job(s) }
  start(do: cron, every: Ms(10_000))
}

/// Job that Syncs Hex Package Data
fn job(state: State) -> Nil {
  let utc = {
    birl.utc_now()
    |> birl.to_iso8601
  }
  wisp.log_info("Start Cron Job at: " <> utc)
  // pp.debug(state)

  // let assert Ok(wisp) = hex.fetch_package("mist", state.hex_key)
  // // get_most_recent_version(wisp)
  // //let download_data = create_download_json(wisp)
  // let wisp_data = create_package_json(wisp)
  // tinybird.insert_data_tb(wisp_data, state.tinybird_key, "packages")
  let x = get_gleam_packages(state.tinybird_key)
  io.println("RESPONSE")
  pp.debug(x)

  Nil
}

/// Returns max time from packages table minus 8 hours in case a job failed
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

fn first_timestamp(packages: List(hexpm.Package), state: State) -> Time {
  case packages {
    [] -> state.newest
    [package, ..] -> {
      case birl.compare(package.updated_at, state.newest) {
        order.Gt -> package.updated_at
        _ -> state.newest
      }
    }
  }
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

// fn fetch_release(release: hexpm.PackageRelease, hex_key: String) {
//   let assert Ok(url) = uri.parse(release.url)

//   use response <- try(
//     request.new()
//     |> request.set_host("hex.pm")
//     |> request.set_path(url.path)
//     |> request.prepend_header("authorization", hex_key)
//     |> hackney.send
//     |> result.map_error(error.HttpClientError),
//   )

//   json.decode(response.body, using: hexpm.decode_release)
//   |> result.map_error(error.JsonDecodeError)
//   |> io.debug()
// }

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
  |> io.debug()
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
  |> io.debug()
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
