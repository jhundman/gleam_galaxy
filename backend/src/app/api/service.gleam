import app/models.{type Statistics, Meta}
import birl.{type Time}
import gleam/dynamic.{type DecodeError, type Dynamic} as dyn
import gleam/io
import gleam/json
import gleam/list

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
        models.Meta,
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
