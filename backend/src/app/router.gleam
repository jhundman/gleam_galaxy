import app/api/web.{handle_api_request}
import gleam/io
import gleam/json
import wisp.{type Request, type Response}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes()
  use req <- wisp.handle_head(req)
  use <- default_responses()
  handle_request(req)
}

pub fn handle_request(req: Request, tb_key: String) -> Response {
  use _req <- middleware(req)

  case wisp.path_segments(req) {
    [] -> {
      json.object([#("message", json.string("Hello World"))])
      |> json.to_string_builder
      |> wisp.json_response(200)
    }

    ["api", ..] -> handle_api_request(req, tb_key)

    _ -> {
      wisp.response(404)
    }
  }
}

pub fn default_responses(handle_request: fn() -> wisp.Response) -> wisp.Response {
  let response = handle_request()
  case response.status {
    404 | 405 -> {
      json.object([#("message", json.string("Are you lost fellow traveler?"))])
      |> json.to_string_builder
      |> wisp.json_response(404)
    }
    400 -> {
      json.object([#("message", json.string("Try again"))])
      |> json.to_string_builder
      |> wisp.json_response(400)
    }

    _ -> response
  }
}
