import birl.{type Time}
import sqlight

// Service State
pub type State {
  State(
    page: Int,
    last_updated_at: Time,
    hex_key: String,
    db_connection: sqlight.Connection,
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
