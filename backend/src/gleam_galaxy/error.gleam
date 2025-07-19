import gleam/hackney
import gleam/json
import sqlight

pub type Error {
  HttpClientError(hackney.Error)
  JsonDecodeError(json.DecodeError)
  DatabaseError(sqlight.Error)
}
