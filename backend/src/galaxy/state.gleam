import birl.{type Time}

pub type State {
  State(
    page: Int,
    newest: Time,
    hex_key: String,
    tinybird_key: String,
    updated_at: Time,
  )
}
