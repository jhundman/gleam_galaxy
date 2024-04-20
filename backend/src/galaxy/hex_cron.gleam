import birl.{type Time}
import birl/duration
import galaxy/error.{type Error}
import gleam/dynamic
import gleam/hackney
import gleam/hexpm
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/uri
import shakespeare/actors/periodic.{Ms, start}
import wisp

pub fn try(a: Result(a, e), f: fn(a) -> Result(b, e)) -> Result(b, e) {
  case a {
    Ok(a) -> f(a)
    Error(e) -> Error(e)
  }
}

type State {
  State(
    page: Int,
    newest: Time,
    hex_key: String,
    tinybird_key: String,
    updated_at: Time,
  )
}

pub fn start_cron(hex_key: String, tinybird_key: String) {
  wisp.log_info("Start Scheduler")

  let latest_ts =
    birl.utc_now()
    |> birl.subtract(duration.days(5))

  let state =
    State(
      page: 1,
      newest: latest_ts,
      hex_key: hex_key,
      tinybird_key: tinybird_key,
      updated_at: birl.utc_now(),
    )

  // io.debug(state)

  let cron = fn() { do_cron(state) }
  start(do: cron, every: Ms(10_000))
}

fn do_cron(state: State) -> Nil {
  let utc =
    birl.utc_now()
    |> birl.to_iso8601
  wisp.log_info("Start Cron Job at: " <> utc <> ", Hex Key: " <> "Done")

  Nil
}

fn sync_packages(state: State) {
  todo
}

fn bulk_fetch_packages(state: State) {
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

fn fetch_release(release: hexpm.PackageRelease, hex_key: String) {
  let assert Ok(url) = uri.parse(release.url)

  use response <- try(
    request.new()
    |> request.set_host("hex.pm")
    |> request.set_path(url.path)
    |> request.prepend_header("authorization", hex_key)
    |> hackney.send
    |> result.map_error(error.HttpClientError),
  )

  json.decode(response.body, using: hexpm.decode_release)
  |> result.map_error(error.JsonDecodeError)
  |> io.debug()
}

fn sync_downloads() {
  todo
}

fn fetch_package(package_name: String, hex_key: String) {
  todo
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
  io.debug(package)

  Ok(package)
}
// fetch_package("wisp", state.hex_key)
// let release =
//   hexpm.PackageRelease(
//     inserted_at: birl.utc_now(),
//     url: "https://hex.pm/api/packages/wisp/releases/0.13.0",
//     version: "0.13.0",
//   )
// fetch_release(release, state.hex_key)
