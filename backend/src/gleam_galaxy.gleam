import dot_env
import gleam/erlang/process
import gleam/io
import gleam_galaxy/job/job
import gleam_galaxy/router
import glenvy/dotenv
import glenvy/env
import mist
import simplifile
import sqlight
import wisp

fn get_env_with_log(name: String, default: String) -> String {
  case env.get_string(name) {
    Ok(key) -> {
      io.println("Has " <> name)
      key
    }
    Error(_) -> {
      io.println("Missing " <> name)
      default
    }
  }
}

fn init_tables(conn: sqlight.Connection) {
  let assert Ok(sql) = simplifile.read("./src/sql/001_setup.sql")
  io.println("INIT TABLES")
  let assert Ok(Nil) = sqlight.exec(sql, conn)
  io.println("INIT COMPLETE")
}

pub fn main() {
  io.println("STARTING UP")
  wisp.configure_logger()
  dot_env.load()

  let secret_key_base = wisp.random_string(64)

  // Env vars
  let _ = dotenv.load()

  let hex_key = get_env_with_log("HEX_API_KEY", "")
  let tinybird_key = get_env_with_log("TINYBIRD_KEY", "")
  let sqlite_path = get_env_with_log("SQLITE_DB", "")

  use conn <- sqlight.with_connection(sqlite_path)

  init_tables(conn)

  let assert Ok(_) =
    router.handle_request(_, conn)
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  // Start Cron
  // let assert Ok(_) = job.start_sync(hex_key, tinybird_key)

  process.sleep_forever()
}
