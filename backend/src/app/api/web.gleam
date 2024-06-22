import gleam/io
import gleam/json
import gleam/list
import gleam/result
import wisp.{type Request, type Response}

pub fn handle_api_request(req: Request) -> Response {
  case list.drop(wisp.path_segments(req), 1) {
    [] -> {
      io.println("made it here 2")
      wisp.response(200)
    }
    _ -> {
      io.println("made it here")
      wisp.response(404)
    }
  }
}
