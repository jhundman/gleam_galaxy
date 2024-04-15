import gleam/io
import shakespeare/actors/periodic.{Ms, start}
import birl
import wisp

// import gleam/erlang/process

pub fn start_cron(hex_key: String) {
  wisp.log_info("Start Scheduler")
  let cron = fn() { do_cron(hex_key) }
  start(do: cron, every: Ms(1000))
}

pub fn do_cron(hex_key: String) -> Nil {
  let utc =
    birl.utc_now()
    |> birl.to_iso8601
  wisp.log_info("Start Cron Job at: " <> utc <> ", Hex Key: " <> hex_key)
}
