import birl.{type Time}
import birl/duration
import galaxy/cron/hex
import galaxy/cron/tinybird
import galaxy/error.{type Error}
import galaxy/state.{type State}
import gleam/dict
import gleam/dynamic
import gleam/hackney
import gleam/hexpm.{type Package}
import gleam/int
import gleam/io
import gleam/json
import gleam/option
import gleam/result
import pprint as pp
import shakespeare/actors/periodic.{Ms, start}
import wisp

pub fn try(a: Result(a, e), f: fn(a) -> Result(b, e)) -> Result(b, e) {
  case a {
    Ok(a) -> f(a)
    Error(e) -> Error(e)
  }
}

pub fn start_cron(hex_key: String, tinybird_key: String) {
  wisp.log_info("Start Scheduler")

  let latest_ts = tinybird.get_max_package_updated_at(tinybird_key)

  let latest_ts = case latest_ts {
    Ok(t) -> t
    Error(_) ->
      birl.utc_now()
      |> birl.subtract(duration.years(5))
  }

  io.println("\nLatest TS")
  pp.debug(latest_ts)

  let s =
    state.State(
      page: 1,
      newest: latest_ts,
      hex_key: hex_key,
      tinybird_key: tinybird_key,
      updated_at: birl.utc_now(),
    )

  let cron = fn() { do_cron(s) }
  start(do: cron, every: Ms(10_000))
}

fn do_cron(state: State) -> Nil {
  let utc = {
    birl.utc_now()
    |> birl.to_iso8601
  }
  wisp.log_info("Start Cron Job at: " <> utc)
  pp.debug(state)

  let assert Ok(wisp) = hex.fetch_package("wisp", state.hex_key)
  let wisp_data = create_package_json(wisp, state)
  tinybird.insert_data_tb(wisp_data, state.tinybird_key, "packages")

  Nil
}

pub fn create_package_json(pkg: Package, state: State) {
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

  let state_upated_at =
    state.updated_at
    |> birl.to_iso8601()
    |> json.string()

  // io.debug(pkg)

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
      #("inserted_at", state_upated_at),
    ])
  }
  json.to_string(x)
  |> io.debug()
}
// fn sync_packages(state: State) {
//   todo
// }

// fn bulk_fetch_packages(state: State) {
//   use response <- result.try(
//     request.new()
//     |> request.set_host("hex.pm")
//     |> request.set_path("/api/packages")
//     |> request.set_query([
//       #("sort", "updated_at"),
//       #("page", int.to_string(state.page)),
//     ])
//     |> request.prepend_header("authorization", state.hex_key)
//     |> hackney.send
//     |> result.map_error(error.HttpClientError),
//   )
//   use all_packages <- result.try(
//     json.decode(response.body, using: dynamic.list(of: hexpm.decode_package))
//     |> result.map_error(error.JsonDecodeError),
//   )
//   Ok(all_packages)
// }

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

// fn sync_downloads() {
//   todo
// }

// // fetch_package("wisp", state.hex_key)
// // let release =
// //   hexpm.PackageRelease(
// //     inserted_at: birl.utc_now(),
// //     url: "https://hex.pm/api/packages/wisp/releases/0.13.0",
// //     version: "0.13.0",
// //   )
// // fetch_release(release, state.hex_key)
