import gleam/hackney
import gleam/http
import gleam/http/request

// import gleam/http/response
// import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam_galaxy/api/service
import gleam_galaxy/error
import wisp.{type Request, type Response}

pub fn handle_api_request(req: Request, tb_key: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  case list.drop(wisp.path_segments(req), 1) {
    ["search"] -> search_packages(req, tb_key)
    ["home"] -> get_home()
    ["package", pkg] -> get_package(pkg, tb_key)
    [] -> {
      io.println("API Home")
      wisp.response(200)
    }
    _ -> {
      io.println("made it here")
      wisp.response(404)
    }
  }
}

fn search_packages(req, tb_key: String) -> Response {
  case wisp.get_query(req) {
    [#("query", q)] -> {
      let assert Ok(response) =
        request.new()
        |> request.set_host("api.us-east.tinybird.co")
        |> request.set_path("/v0/pipes/package_search.json")
        |> request.set_query([#("query", q)])
        |> request.prepend_header("Authorization", "Bearer " <> tb_key)
        |> hackney.send
        |> result.map_error(error.HttpClientError)

      let assert Ok(search_response) =
        json.decode(response.body, using: service.decode_search)
        |> result.map_error(error.JsonDecodeError)

      service.encode_search(search_response)
      |> json.to_string_builder()
      |> wisp.json_response(200)
    }
    _ -> {
      wisp.response(400)
    }
  }
}

// json.object([#("message", json.string("You searched: " <> q))])
// |> json.to_string_builder
// |> wisp.json_response(200)

fn get_home() -> Response {
  json.object([#("message", json.string("Home Data"))])
  |> json.to_string_builder
  |> wisp.json_response(200)
}

fn get_package(pkg: String, tb_key: String) {
  let assert Ok(response) =
    request.new()
    |> request.set_host("api.us-east.tinybird.co")
    |> request.set_path("/v0/pipes/get_package.json")
    |> request.set_query([#("pkg", pkg)])
    |> request.prepend_header("Authorization", "Bearer " <> tb_key)
    |> hackney.send()

  let assert Ok(pkg_response) =
    json.decode(response.body, using: service.decode_package)
    |> result.map_error(error.JsonDecodeError)

  service.encode_package(pkg_response)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}
