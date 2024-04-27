import birl
import birl/duration
import galaxy/error
import gleam/dynamic.{type DecodeError, type Dynamic, DecodeError} as dyn
import gleam/hackney
import gleam/http.{type Method}
import gleam/http/request
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import pprint as pp

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

pub fn decode_max_package_updated_at(
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
    json.decode(response.body, using: decode_max_package_updated_at)
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

// Get Gleam Packages
pub type PackageName {
  PackageName(package: String)
}

pub type ListOfPackages {
  ListOfPackages(
    meta: List(Meta),
    data: List(PackageName),
    rows: Int,
    statistics: Statistics,
  )
}

fn decode_gleam_packages(
  data: Dynamic,
) -> Result(ListOfPackages, List(DecodeError)) {
  io.println("START DECODE")
  dyn.decode4(
    ListOfPackages,
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
      dyn.list(dyn.decode1(PackageName, dyn.field("package_name", dyn.string))),
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
    json.decode(response.body, using: decode_gleam_packages)
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
