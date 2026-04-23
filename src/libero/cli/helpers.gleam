//// Shared helpers for CLI scaffold commands (new, add).

import gleam/string
import libero/format
import simplifile

/// Write a file, running `gleam format` on .gleam files first.
pub fn write_formatted(
  path path: String,
  content content: String,
) -> Result(Nil, simplifile.FileError) {
  let formatted = case string.ends_with(path, ".gleam") {
    True -> format.format_gleam(content)
    False -> content
  }
  simplifile.write(path, formatted)
}

/// Map a simplifile.FileError to a user-facing String error, threading
/// the success value through a continuation.
/// nolint: stringly_typed_error -- CLI module, String errors are user-facing messages
pub fn map_err(
  result: Result(a, simplifile.FileError),
  next: fn(a) -> Result(Nil, String),
) -> Result(Nil, String) {
  case result {
    Ok(value) -> next(value)
    Error(err) -> Error(simplifile.describe_error(err))
  }
}
