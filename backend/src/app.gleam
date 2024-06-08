import app/job/job
import app/router
import dot_env
import gleam/erlang/process
import gleam/result.{try}
import glenvy/dotenv
import glenvy/env
import mist
import wisp

// import gleam/io

pub fn main() {
  wisp.configure_logger()
  dot_env.load()

  let secret_key_base = wisp.random_string(64)

  // Env vars
  let _ = dotenv.load()
  use hex_key <- try(env.get_string("HEX_API_KEY"))
  use tinybird_key <- try(env.get_string("TINYBIRD_KEY"))

  let assert Ok(_) =
    wisp.mist_handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  // Start Cron
  let assert Ok(_) = job.start_sync(hex_key, tinybird_key)

  process.sleep_forever()
  Ok(Nil)
}
