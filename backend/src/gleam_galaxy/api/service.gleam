import gleam/dynamic.{type DecodeError, type Dynamic} as dyn
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam_galaxy/models.{type Statistics, Meta}

/// Search
pub type SearchResponse {
  SearchResponse(
    meta: List(models.Meta),
    data: List(SearchRecord),
    rows: Int,
    rows_before_limit_at_least: Int,
    statistics: Statistics,
  )
}

pub type SearchRecord {
  SearchRecord(
    package_name: String,
    description: String,
    downloads_all_time: Int,
  )
}

pub fn decode_search(data: Dynamic) -> Result(SearchRecord, List(DecodeError)) {
  dyn.decode3(
    SearchRecord,
    dyn.field(0, dyn.string),
    dyn.field(1, dyn.string),
    dyn.field(2, dyn.int),
  )(data)
}

pub fn encode_search(search: List(SearchRecord)) {
  let recs =
    list.map(search, fn(x) {
      json.object([
        #("package_name", json.string(x.package_name)),
        #("description", json.string(x.description)),
        #("downloads_all_time", json.int(x.downloads_all_time)),
      ])
    })

  json.object([#("data", json.preprocessed_array(recs))])
}

/// Package
pub type PackageResponse {
  PackageResponse(
    meta: List(models.Meta),
    data: List(PackageRecord),
    rows: Int,
    statistics: Statistics,
  )
}

pub type PackageHistoryResponse {
  PackageHistoryResponse(
    meta: List(models.Meta),
    data: List(PackageHistory),
    rows: Int,
    statistics: Statistics,
  )
}

pub fn decode_package(
  data: Dynamic,
) -> Result(PackageResponse, List(DecodeError)) {
  dyn.decode4(
    PackageResponse,
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
      dyn.list(dyn.decode9(
        PackageRecord,
        dyn.field("package_name", dyn.string),
        dyn.field("hex_url", dyn.string),
        dyn.field("description", dyn.string),
        dyn.field("licenses", dyn.list(dyn.string)),
        dyn.field("repository_url", dyn.string),
        dyn.field("owners", dyn.list(dyn.string)),
        dyn.field("downloads_all_time", dyn.int),
        dyn.field("hex_updated_at", dyn.string),
        dyn.field("hex_inserted_at", dyn.string),
      )),
    ),
    dyn.field("rows", dyn.int),
    dyn.field(
      "statistics",
      dyn.decode3(
        models.Statistics,
        dyn.field("elapsed", dyn.float),
        dyn.field("rows_read", dyn.int),
        dyn.field("bytes_read", dyn.int),
      ),
    ),
  )(data)
}

/// Package Record
fn string_to_list(data: Dynamic) -> Result(List(String), List(DecodeError)) {
  use str <- result.try(dyn.string(data))
  case str {
    "" -> Ok([])
    _ -> Ok(string.split(str, ","))
  }
}

pub type PackageRecord {
  PackageRecord(
    package_name: String,
    hex_url: String,
    description: String,
    licenses: List(String),
    repository_url: String,
    owners: List(String),
    downloads_all_time: Int,
    hex_updated_at: String,
    hex_inserted_at: String,
  )
}

pub fn decode_package_record(
  row: Dynamic,
) -> Result(PackageRecord, List(DecodeError)) {
  dyn.decode9(
    PackageRecord,
    dyn.element(0, dyn.string),
    dyn.element(1, dyn.string),
    dyn.element(2, dyn.string),
    dyn.element(3, string_to_list),
    dyn.element(4, dyn.string),
    dyn.element(5, string_to_list),
    dyn.element(6, dyn.int),
    dyn.element(7, dyn.string),
    dyn.element(8, dyn.string),
  )(row)
}

// Package history
pub type PackageHistory {
  PackageHistory(package_name: String, downloads: Int, date: String)
}

pub fn decode_package_history(
  data: Dynamic,
) -> Result(PackageHistory, List(DecodeError)) {
  dyn.decode3(
    PackageHistory,
    dyn.element(0, dyn.string),
    dyn.element(1, dyn.int),
    dyn.element(2, dyn.string),
  )(data)
}

// ,
pub fn encode_package(pkg: PackageRecord, pkg_history: List(PackageHistory)) {
  let recs = [
    #("package_name", json.string(pkg.package_name)),
    #("hex_url", json.string(pkg.hex_url)),
    #("description", json.string(pkg.description)),
    #("licenses", json.array(from: pkg.licenses, of: json.string)),
    #("repository_url", json.string(pkg.repository_url)),
    #("owners", json.array(from: pkg.owners, of: json.string)),
    #("downloads_all_time", json.int(pkg.downloads_all_time)),
    #("hex_updated_at", json.string(pkg.hex_updated_at)),
    #("hex_inserted_at", json.string(pkg.hex_inserted_at)),
  ]

  let history =
    list.map(pkg_history, fn(x) {
      json.object([
        #("package_name", json.string(x.package_name)),
        #("downloads", json.int(x.downloads)),
        #("date", json.string(x.date)),
      ])
    })

  json.object([
    #("data", json.object(recs)),
    #("history", json.preprocessed_array(history)),
  ])
}

/// Home
pub type HomeRecord {
  HomeRecord(num_packages: Int, total_downloads: Int)
}

pub fn decode_home(row: Dynamic) -> Result(HomeRecord, List(DecodeError)) {
  dyn.decode2(HomeRecord, dyn.element(0, dyn.int), dyn.element(1, dyn.int))(row)
}

pub fn encode_home(home: HomeRecord) {
  json.object([
    #(
      "data",
      json.object([
        #("num_packages", json.int(home.num_packages)),
        #("total_downloads", json.int(home.total_downloads)),
      ]),
    ),
  ])
}
