import birl.{type Time}
import birl/duration
import galaxy/error.{type Error}
import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic, DecodeError} as dyn
import gleam/dynamic
import gleam/function
import gleam/hackney
import gleam/hexpm
import gleam/http/request
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/order
import gleam/result
import gleam/string
import gleam/uri

pub type Statistics {
  Statistics(elapsed: Float, rows_read: Int, bytes_read: Int)
}

pub type Meta {
  Meta(name: String, data_type: String)
}

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

fn decode_max_package_updated_at(
  data: Dynamic,
) -> Result(MaxUpdate, List(DecodeError)) {
  dyn.decode4(
    MaxUpdate,
    dyn.field(
      "meta",
      dyn.list(dyn.decode2(
        Meta,
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
        Statistics,
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
    Error(_) -> "Error"
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
