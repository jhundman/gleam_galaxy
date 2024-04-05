import gleam/json

pub type Error {
  JsonDecodeError(json.DecodeError)
}
