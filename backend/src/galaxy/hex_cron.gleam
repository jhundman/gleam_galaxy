import gleam/io
import shakespeare/actors/periodic.{Ms, start}
import birl

// import gleam/erlang/process

pub fn start_cron() {
  start(do: do_cron, every: Ms(1000))
}

pub fn do_cron() -> Nil {
  let utc =
    birl.utc_now()
    |> birl.to_time_string
  io.println("Scheduled Task" <> utc)
}
