import gleam/io
import shakespeare/actors/periodic.{Ms, start}
import birl.{type Time}
import birl/duration
import wisp
import gleam/hackney
import gleam/http/request
import gleam/list
import gleam/json
import gleam/order
import gleam/result
import gleam/string
import gleam/uri
import gleam/hexpm
import galaxy/error.{type Error}

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
  start(do: cron, every: Ms(5000))
}

fn do_cron(state: State) -> Nil {
  let utc =
    birl.utc_now()
    |> birl.to_iso8601
  wisp.log_info("Start Cron Job at: " <> utc <> ", Hex Key: " <> "Done")

  // fetch_package("wisp", state.hex_key)
  let release =
    hexpm.PackageRelease(
      inserted_at: birl.utc_now(),
      url: "https://hex.pm/api/packages/wisp/releases/0.13.0",
      version: "0.13.0",
    )
  fetch_release(release, state.hex_key)
  Nil
}

fn bulk_fetch_packages() {
  todo
}

fn fetch_package(package_name: String, hex_key: String) {
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
