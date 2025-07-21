import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/io
import gleam_galaxy/router
import mist
import simplifile
import sqlight
import wisp
import wisp/wisp_mist

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
  dot_env.load_default()

  let secret_key_base = wisp.random_string(64)

  let hex_key = get_env_with_log("HEX_API_KEY", "")
  let sqlite_path = get_env_with_log("SQLITE_DB", "")
  let cron_secret = get_env_with_log("CRON_SECRET", "")

  use conn <- sqlight.with_connection(sqlite_path)

  init_tables(conn)

  let assert Ok(_) =
    wisp_mist.handler(
      router.handle_request(_, conn, hex_key, cron_secret),
      secret_key_base,
    )
    |> mist.new
    |> mist.port(8080)
    |> mist.start
  process.sleep_forever()
}
