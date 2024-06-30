import birl
import gleam/dynamic.{type DecodeError, type Dynamic} as dyn

// import gleam/io
import gleam/json
import gleam/list
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

pub fn decode_search(data: Dynamic) -> Result(SearchResponse, List(DecodeError)) {
  dyn.decode5(
    SearchResponse,
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
      dyn.list(dyn.decode3(
        SearchRecord,
        dyn.field("package_name", dyn.string),
        dyn.field("description", dyn.string),
        dyn.field("downloads_all_time", dyn.int),
      )),
    ),
    dyn.field("rows", dyn.int),
    dyn.field("rows_before_limit_at_least", dyn.int),
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

pub fn encode_search(search: SearchResponse) {
  let recs =
    list.map(search.data, fn(x) {
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
    // inserted_at: Time,
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

pub fn encode_package(pkg: PackageResponse) {
  let recs =
    list.map(pkg.data, fn(x) {
      json.object([
        #("package_name", json.string(x.package_name)),
        #("hex_url", json.string(x.hex_url)),
        #("description", json.string(x.description)),
        #("licenses", json.array(from: x.licenses, of: json.string)),
        #("repository_url", json.string(x.repository_url)),
        #("owners", json.array(from: x.owners, of: json.string)),
        #("downloads_all_time", json.int(x.downloads_all_time)),
        #("hex_updated_at", json.string(x.hex_updated_at)),
        #("hex_inserted_at", json.string(x.hex_inserted_at)),
      ])
    })

  json.object([#("data", json.preprocessed_array(recs))])
}
