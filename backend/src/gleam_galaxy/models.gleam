import birl.{type Time}

// Service State
pub type State {
  State(
    page: Int,
    last_updated_at: Time,
    hex_key: String,
    tinybird_key: String,
    current_time: Time,
  )
}

// Tinybird Common Models
pub type Statistics {
  Statistics(elapsed: Float, rows_read: Int, bytes_read: Int)
}

pub type Meta {
  Meta(name: String, data_type: String)
}
