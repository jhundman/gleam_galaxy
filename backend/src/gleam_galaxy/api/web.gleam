import gleam/hackney
import gleam/http
import gleam/http/request

// import gleam/http/response
// import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/otp/task
import gleam/result
import gleam_galaxy/api/service
import gleam_galaxy/error
import wisp.{type Request, type Response}

pub fn handle_api_request(req: Request, tb_key: String) -> Response {
  use <- wisp.require_method(req, http.Get)
  case list.drop(wisp.path_segments(req), 1) {
    ["search"] -> search_packages(req, tb_key)
    ["home"] -> get_home(tb_key)
    ["package", pkg] -> get_package(pkg, tb_key)
    [] -> {
      json.object([#("message", json.string("Hello World"))])
      |> json.to_string_builder
      |> wisp.json_response(200)
    }
    _ -> {
      wisp.response(404)
    }
  }
}

fn search_packages(req, tb_key: String) -> Response {
  io.debug("Here")
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

fn get_home(tb_key: String) -> Response {
  let assert Ok(response) =
    request.new()
    |> request.set_host("api.us-east.tinybird.co")
    |> request.set_path("/v0/pipes/home_summary.json")
    |> request.prepend_header("Authorization", "Bearer " <> tb_key)
    |> hackney.send()

  let assert Ok(home_response) =
    json.decode(response.body, using: service.decode_home)
    |> result.map_error(error.JsonDecodeError)

  service.encode_home(home_response)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}

fn get_package(pkg: String, tb_key: String) {
  let package_header = task.async(fn() { get_package_header(pkg, tb_key) })
  let package_history = task.async(fn() { get_package_history(pkg, tb_key) })

  let package_header = task.await(package_header, 500)
  let package_history = task.await(package_history, 500)

  service.encode_package(package_header, package_history)
  |> json.to_string_builder()
  |> wisp.json_response(200)
}

fn get_package_header(pkg: String, tb_key: String) {
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

  pkg_response
}

fn get_package_history(pkg: String, tb_key: String) {
  let assert Ok(response) =
    request.new()
    |> request.set_host("api.us-east.tinybird.co")
    |> request.set_path("/v0/pipes/package_downloads.json")
    |> request.set_query([#("pkg", pkg)])
    |> request.prepend_header("Authorization", "Bearer " <> tb_key)
    |> hackney.send()

  let assert Ok(pkg_history_response) =
    json.decode(response.body, using: service.decode_package_history)
    |> result.map_error(error.JsonDecodeError)

  pkg_history_response
}
