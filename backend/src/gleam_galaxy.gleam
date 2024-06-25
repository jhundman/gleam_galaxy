import dot_env
import gleam/erlang/process
import gleam/io
import gleam/result.{try}
import gleam_galaxy/job/job
import gleam_galaxy/router
import glenvy/dotenv
import glenvy/env
import mist
import wisp

// import gleam/io

pub fn main() {
  io.println("STARTING UP")
  wisp.configure_logger()
  dot_env.load()

  let secret_key_base = wisp.random_string(64)

  // Env vars
  let _ = dotenv.load()
  let hex_key = case env.get_string("HEX_API_KEY") {
    Ok(key) -> {
      io.println("Has Hex Key")
      key
    }
    Error(_) -> {
      io.println("Missing Hex Key")
      ""
    }
  }
  let tinybird_key = case env.get_string("TINYBIRD_KEY") {
    Ok(key) -> {
      io.println("Has TB Key")
      key
    }
    Error(_) -> {
      io.println("Missing TB Key")
      ""
    }
  }

  let assert Ok(_) =
    router.handle_request(_, tinybird_key)
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  // Start Cron
  let assert Ok(_) = job.start_sync(hex_key, tinybird_key)

  process.sleep_forever()
}
