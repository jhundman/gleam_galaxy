import gleam/time/timestamp.{type Timestamp}
import sqlight

// Service State
pub type State {
  State(
    page: Int,
    last_updated_at: Timestamp,
    hex_key: String,
    db_connection: sqlight.Connection,
    current_time: Timestamp,
  )
}

// Tinybird Common Models
pub type Statistics {
  Statistics(elapsed: Float, rows_read: Int, bytes_read: Int)
}

pub type Meta {
  Meta(name: String, data_type: String)
}
