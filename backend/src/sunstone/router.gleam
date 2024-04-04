import wisp.{type Request, type Response}
import gleam/string_builder
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/hackney
import gleam/json
import gleam/result
import gleam/io

pub fn handle_request(req: Request) -> Response {
  use req <- middleware(req)

  // ROUTES
  case wisp.path_segments(req) {
    [] -> home(req)
    ["test"] -> test_func(req)
    _ -> wisp.not_found()
  }
}

fn home(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  let res =
    [#("message", json.string("home"))]
    |> json.object()
    |> json.to_string_builder()
    |> Ok

  case res {
    Ok(json) -> wisp.json_response(json, 200)
    Error(_) -> wisp.unprocessable_entity()
  }
}

fn test_func(_req: Request) -> Response {
  [#("message", json.string("howdy"))]
  |> json.object()
  |> json.to_string_builder()
  |> wisp.json_response(200)
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}
