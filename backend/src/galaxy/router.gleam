import wisp.{type Request, type Response}
import gleam/io

// Wisp has functions for logging messages using the BEAM logger.
//
// Messages can be logged at different levels. From most important to least
// important they are:
// - emergency
// - alert
// - critical
// - error
// - warning
// - notice
// - info
// - debug
//

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  // let req = wisp.method_override(req)
  // use <- wisp.log_request(req)
  // use <- wisp.rescue_crashes
  // use req <- wisp.handle_head(req)

  handle_request(req)
}

pub fn handle_request(req: Request) -> Response {
  use _req <- middleware(req)

  case wisp.path_segments(req) {
    [] -> {
      wisp.log_info("The home page")
      io.println("Hi this is home")
      wisp.ok()
    }

    _ -> {
      wisp.log_warning("User requested a route that does not exist")
      wisp.not_found()
    }
  }
}
