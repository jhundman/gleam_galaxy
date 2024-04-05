import wisp.{type Request, type Response}
import gleam/string_builder
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response
import gleam/hackney
import gleam/json
import gleam/result
import gleam/io
import gleam/dynamic as dyn

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

pub type Todo {
  Todo(user_id: Int, id: Int, title: String, completed: Bool)
}

fn test_func(_req: Request) -> Response {
  let response =
    request.new()
    |> request.set_host("jsonplaceholder.typicode.com")
    |> request.set_path("/todos/5")
    |> hackney.send()

  let body = case response {
    Ok(response) -> response.body
    Error(_) -> ""
  }

  let decoded_encoded =
    from_string(body)
    |> result.map(to_string)

  case decoded_encoded {
    Ok(dec) -> wisp.json_response(dec, 200)
    Error(_) -> wisp.unprocessable_entity()
  }
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

pub fn to_json(t: Todo) {
  json.object([
    #("user_id", json.int(t.user_id)),
    #("id", json.int(t.id)),
    #("title", json.string(t.title)),
    #("completed", json.bool(t.completed)),
  ])
}

pub fn to_string(t: Todo) {
  json.to_string_builder(to_json(t))
}

pub fn get_decoder_foo() {
  dyn.decode4(
    Todo,
    dyn.field("userId", of: dyn.int),
    dyn.field("id", of: dyn.int),
    dyn.field("title", of: dyn.string),
    dyn.field("completed", of: dyn.bool),
  )
}

pub fn from_string(json_str: String) {
  json.decode(json_str, get_decoder_foo())
}
