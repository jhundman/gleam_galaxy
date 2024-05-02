import birl.{type Time}

// Service State
pub type State {
  State(
    page: Int,
    newest: Time,
    hex_key: String,
    tinybird_key: String,
    updated_at: Time,
  )
}

// Tinybird Common Models
pub type Statistics {
  Statistics(elapsed: Float, rows_read: Int, bytes_read: Int)
}

pub type Meta {
  Meta(name: String, data_type: String)
}
