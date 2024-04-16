import gleam/hackney
import gleam/json

pub type Error {
  HttpClientError(hackney.Error)
  JsonDecodeError(json.DecodeError)
}
