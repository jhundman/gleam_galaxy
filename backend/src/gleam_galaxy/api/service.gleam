import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type DecodeError}
import gleam/json
import gleam/list

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
  let decoder = {
    use package_name <- decode.then(decode.at([0], decode.string))
    use description <- decode.then(decode.at([1], decode.string))
    use downloads_all_time <- decode.then(decode.at([2], decode.int))
    decode.success(SearchRecord(package_name, description, downloads_all_time))
  }
  decode.run(data, decoder)
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
  let meta_decoder = {
    use name <- decode.field("name", decode.string)
    use type_ <- decode.field("type", decode.string)
    decode.success(Meta(name, type_))
  }

  let package_record_decoder = {
    use package_name <- decode.field("package_name", decode.string)
    use hex_url <- decode.field("hex_url", decode.string)
    use description <- decode.field("description", decode.string)
    use licenses <- decode.field("licenses", decode.list(decode.string))
    use repository_url <- decode.field("repository_url", decode.string)
    use owners <- decode.field("owners", decode.list(decode.string))
    use downloads_all_time <- decode.field("downloads_all_time", decode.int)
    use hex_updated_at <- decode.field("hex_updated_at", decode.string)
    use hex_inserted_at <- decode.field("hex_inserted_at", decode.string)
    decode.success(PackageRecord(
      package_name,
      hex_url,
      description,
      licenses,
      repository_url,
      owners,
      downloads_all_time,
      hex_updated_at,
      hex_inserted_at,
    ))
  }

  let statistics_decoder = {
    use elapsed <- decode.field("elapsed", decode.float)
    use rows_read <- decode.field("rows_read", decode.int)
    use bytes_read <- decode.field("bytes_read", decode.int)
    decode.success(models.Statistics(elapsed, rows_read, bytes_read))
  }

  let decoder = {
    use meta <- decode.field("meta", decode.list(meta_decoder))
    use data <- decode.field("data", decode.list(package_record_decoder))
    use rows <- decode.field("rows", decode.int)
    use statistics <- decode.field("statistics", statistics_decoder)
    decode.success(PackageResponse(meta, data, rows, statistics))
  }

  decode.run(data, decoder)
}

/// Package Record
fn string_to_list(data: Dynamic) -> Result(List(String), List(DecodeError)) {
  let decoder =
    decode.string
    |> decode.map(fn(str) {
      case str {
        "" -> []
        _ -> string.split(str, ",")
      }
    })
  decode.run(data, decoder)
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
  let string_list_decoder =
    decode.new_primitive_decoder("StringList", fn(data) {
      case string_to_list(data) {
        Ok(list) -> Ok(list)
        Error(_) -> Error([])
      }
    })

  let decoder = {
    use package_name <- decode.then(decode.at([0], decode.string))
    use hex_url <- decode.then(decode.at([1], decode.string))
    use description <- decode.then(decode.at([2], decode.string))
    use licenses <- decode.then(decode.at([3], string_list_decoder))
    use repository_url <- decode.then(decode.at([4], decode.string))
    use owners <- decode.then(decode.at([5], string_list_decoder))
    use downloads_all_time <- decode.then(decode.at([6], decode.int))
    use hex_updated_at <- decode.then(decode.at([7], decode.string))
    use hex_inserted_at <- decode.then(decode.at([8], decode.string))
    decode.success(PackageRecord(
      package_name,
      hex_url,
      description,
      licenses,
      repository_url,
      owners,
      downloads_all_time,
      hex_updated_at,
      hex_inserted_at,
    ))
  }
  decode.run(row, decoder)
}

// Package history
pub type PackageHistory {
  PackageHistory(package_name: String, downloads: Int, date: String)
}

pub fn decode_package_history(
  data: Dynamic,
) -> Result(PackageHistory, List(DecodeError)) {
  let decoder = {
    use package_name <- decode.then(decode.at([0], decode.string))
    use downloads <- decode.then(decode.at([1], decode.int))
    use date <- decode.then(decode.at([2], decode.string))
    decode.success(PackageHistory(package_name, downloads, date))
  }
  decode.run(data, decoder)
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
  let decoder = {
    use num_packages <- decode.then(decode.at([0], decode.int))
    use total_downloads <- decode.then(decode.at([1], decode.int))
    decode.success(HomeRecord(num_packages, total_downloads))
  }
  decode.run(row, decoder)
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
