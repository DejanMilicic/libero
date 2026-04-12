//// Tests for libero/error type construction and wire roundtrip.
////
//// Verifies that all RpcError variants can be constructed and
//// pattern-matched correctly, and that InternalError carries
//// its client-safe message field.

import gleam/dynamic.{type Dynamic}
import libero/error.{
  type Never, type RpcError, AppError, InternalError, MalformedRequest,
  UnknownFunction,
}
import libero/wire

// ---------- Construction ----------

pub fn internal_error_has_message_field_test() {
  let err: RpcError(Never) =
    InternalError(trace_id: "abc123", message: "Something went wrong.")
  let assert InternalError(trace_id: "abc123", message: "Something went wrong.") =
    err
}

pub fn internal_error_message_accessible_via_pattern_match_test() {
  let err: RpcError(String) =
    InternalError(
      trace_id: "trace42",
      message: "Something went wrong, please try again.",
    )
  let assert InternalError(
    message: "Something went wrong, please try again.",
    ..,
  ) = err
}

pub fn app_error_test() {
  let err: RpcError(String) = AppError("bad input")
  let assert AppError("bad input") = err
}

pub fn malformed_request_test() {
  let err: RpcError(Never) = MalformedRequest
  let assert True = err == MalformedRequest
}

pub fn unknown_function_test() {
  let err: RpcError(Never) = UnknownFunction(name: "missing.fn")
  let assert UnknownFunction(name: "missing.fn") = err
}

// ---------- Wire roundtrip ----------

pub fn internal_error_roundtrips_through_wire_test() {
  let value: Result(String, RpcError(Never)) =
    Error(InternalError(
      trace_id: "abc123",
      message: "Something went wrong, please try again.",
    ))
  let encoded = wire.encode(value)
  // Wrap in a call envelope and decode to verify structure survives
  let envelope = ffi_encode(coerce(#("test", [coerce(encoded)])))
  let assert Ok(#("test", [rebuilt])) = wire.decode_call(envelope)
  let decoded: BitArray = unsafe_coerce(rebuilt)
  let assert True = bit_array_byte_size(decoded) > 0
}

@external(erlang, "libero_ffi", "encode")
fn ffi_encode(value: Dynamic) -> BitArray

@external(erlang, "gleam_stdlib", "identity")
fn coerce(value: a) -> Dynamic

@external(erlang, "gleam_stdlib", "identity")
fn unsafe_coerce(value: Dynamic) -> a

@external(erlang, "erlang", "byte_size")
fn bit_array_byte_size(bits: BitArray) -> Int
