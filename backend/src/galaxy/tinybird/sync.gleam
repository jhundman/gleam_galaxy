import birl.{type Time}
import birl/duration
import galaxy/error.{type Error}
import galaxy/state.{type State}
import galaxy/tinybird/tinybird.{type Meta, type Statistics}
import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic, DecodeError} as dyn
import gleam/dynamic
import gleam/function
import gleam/hackney
import gleam/hexpm.{type Package}
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import pprint as pp

import gleam/result

pub type UpdateData {
  UpdateData(max_updated_at: String)
}

pub type MaxUpdate {
  MaxUpdate(
    meta: List(Meta),
    data: List(UpdateData),
    rows: Int,
    statistics: Statistics,
  )
}

pub fn decode_max_package_updated_at(
  data: Dynamic,
) -> Result(MaxUpdate, List(DecodeError)) {
  dyn.decode4(
    MaxUpdate,
    dyn.field(
      "meta",
      dyn.list(dyn.decode2(
        tinybird.Meta,
        dyn.field("name", dyn.string),
        dyn.field("type", dyn.string),
      )),
    ),
    dyn.field(
      "data",
      dyn.list(dyn.decode1(UpdateData, dyn.field("max_updated_at", dyn.string))),
    ),
    dyn.field("rows", dyn.int),
    dyn.field(
      "statistics",
      dyn.decode3(
        tinybird.Statistics,
        dyn.field("elapsed", dyn.float),
        dyn.field("rows_read", dyn.int),
        dyn.field("bytes_read", dyn.int),
      ),
    ),
  )(data)
}

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
    json.decode(response.body, using: decode_max_package_updated_at)
    |> result.map_error(error.JsonDecodeError),
  )

  let time = case list.first(max_update.data) {
    Ok(t) -> t.max_updated_at
    Error(_) -> " "
  }

  let latest_ts =
    birl.utc_now()
    |> birl.subtract(duration.years(5))

  birl.parse(time)
  |> result.unwrap(latest_ts)
  |> birl.subtract(duration.days(5))
  |> io.debug()
  |> Ok()
}

// Insert Package
pub fn create_package_json(pkg: Package, state: State) {
  let downloads =
    pkg.downloads
    |> dict.get("all")
    |> result.unwrap(0)
  let x = {
    json.object([
      #("package_name", json.string(pkg.name)),
      #("hex_url", json.string(option.unwrap(pkg.html_url, ""))),
      #("description", json.string(option.unwrap(pkg.meta.description, ""))),
      #("licenses", json.string("")),
      #("repository_url", json.string("")),
      #("downloads_all_time", json.string("")),
      #("hex_updated_at", json.string("")),
      #("hex_inserted_at", json.string("")),
      #("inserted_at", json.string("")),
    ])
  }
  json.to_string(x)
  |> io.debug()
}
