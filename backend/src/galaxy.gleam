import galaxy/router
import dot_env
import envoy
import mist
import wisp
import gleam/erlang/process
import galaxy/hex_cron.{start_cron}

// import filepath
// import gleam/erlang/process
// // import app/web.{Context}

pub fn main() {
  wisp.configure_logger()
  dot_env.load()

  // Load static values that are shared between all requests

  // let assert Ok(secret_key_base) = envoy.get("SECRET_KEY_BASE")
  // let assert Ok(static) = wisp.priv_directory("app")
  // let assert Ok(lustre_ui_static) = wisp.priv_directory("lustre_ui")

  // let ctx =
  //   Context(
  //     db: start_database_pool(),
  //     static: filepath.join(static, "/static"),
  //     lustre_ui_static: filepath.join(lustre_ui_static, "/static"),
  //   )
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp.mist_handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  let assert Ok(_) = start_cron()

  process.sleep_forever()
}
