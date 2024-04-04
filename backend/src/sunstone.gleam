/// The web router, dispatching requests to different handler functions
/// depending on their path.
///
import gleam/erlang/process
import mist
import wisp
import sunstone/router

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp.mist_handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
/// Return a default response when the response from the router has an empty
/// body, likely meaning the request was invalid and was rejected by some
/// middleware.
///
// pub fn default_responses(resp: wisp.Response) -> wisp.Response {
//   use <- bool.guard(when: resp.body != wisp.Empty, return: resp)
//   let body = fn(html) {
//     html
//     |> element.to_document_string_builder
//     |> wisp.html_body(resp, _)
//   }

//   case resp.status {
//     404 -> body(pages.not_found_html())
//     405 -> body(pages.not_found_html())
//     400 -> body(pages.bad_request_html())
//     422 -> body(pages.bad_request_html())
//     413 -> body(pages.entity_too_large_html())
//     500 -> body(pages.internal_server_error_html())
//     _ -> wisp.redirect("/")
//   }
// }
