//// Wire-format tests for libero/wire (ETF).
////
//// ETF encoding is opaque binary, so we test by verifying encode
//// produces non-empty output, and decode_call correctly parses
//// ETF-encoded call envelopes and rejects invalid input.

import gleam/dynamic.{type Dynamic}
import gleam/option.{None, Some}
import libero/wire

// ---------- Encode produces non-empty BitArray ----------

pub fn encode_int_test() {
  let bits = wire.encode(42)
  let assert True = bit_array_byte_size(bits) > 0
}

pub fn encode_string_test() {
  let bits = wire.encode("hello")
  let assert True = bit_array_byte_size(bits) > 0
}

pub fn encode_bool_test() {
  let bits = wire.encode(True)
  let assert True = bit_array_byte_size(bits) > 0
}

pub fn encode_nil_test() {
  let bits = wire.encode(Nil)
  let assert True = bit_array_byte_size(bits) > 0
}

pub fn encode_list_test() {
  let bits = wire.encode([1, 2, 3])
  let assert True = bit_array_byte_size(bits) > 0
}

pub fn encode_none_test() {
  let bits = wire.encode(None)
  let assert True = bit_array_byte_size(bits) > 0
}

pub fn encode_some_test() {
  let bits = wire.encode(Some(7))
  let assert True = bit_array_byte_size(bits) > 0
}

pub fn encode_ok_test() {
  let value: Result(Int, String) = Ok(42)
  let bits = wire.encode(value)
  let assert True = bit_array_byte_size(bits) > 0
}

pub fn encode_error_test() {
  let value: Result(Int, String) = Error("nope")
  let bits = wire.encode(value)
  let assert True = bit_array_byte_size(bits) > 0
}

// ---------- Call envelope decoding ----------

pub fn decode_call_empty_args_test() {
  let envelope = encode_call_envelope("records.list", [])
  let assert Ok(#("records.list", args)) = wire.decode_call(envelope)
  let assert 0 = list_length(args)
}

pub fn decode_call_with_int_arg_test() {
  let envelope = encode_call_envelope("fizzbuzz.classify", [coerce(15)])
  let assert Ok(#("fizzbuzz.classify", args)) = wire.decode_call(envelope)
  let assert 1 = list_length(args)
}

pub fn decode_call_with_string_arg_test() {
  let envelope = encode_call_envelope("records.save", [coerce("hello")])
  let assert Ok(#("records.save", [arg])) = wire.decode_call(envelope)
  let result: String = unsafe_coerce(arg)
  let assert "hello" = result
}

pub fn decode_call_invalid_binary_test() {
  let assert Error(wire.DecodeError(message: "invalid ETF binary")) =
    wire.decode_call(<<0, 1, 2, 3>>)
}

pub fn decode_call_wrong_shape_test() {
  // Encode a plain integer instead of a {name, args} tuple
  let bad = ffi_encode(coerce(42))
  let assert Error(wire.DecodeError(
    message: "invalid call envelope: expected {binary, list}",
  )) = wire.decode_call(bad)
}

// ---------- Helpers ----------

fn encode_call_envelope(
  name: String,
  args: List(Dynamic),
) -> BitArray {
  ffi_encode(coerce(#(name, args)))
}

fn list_length(items: List(a)) -> Int {
  do_length(items, 0)
}

fn do_length(items: List(a), acc: Int) -> Int {
  case items {
    [] -> acc
    [_, ..rest] -> do_length(rest, acc + 1)
  }
}

@external(erlang, "libero_ffi", "encode")
fn ffi_encode(value: Dynamic) -> BitArray

@external(erlang, "gleam_stdlib", "identity")
fn coerce(value: a) -> Dynamic

@external(erlang, "gleam_stdlib", "identity")
fn unsafe_coerce(value: Dynamic) -> a

@external(erlang, "erlang", "byte_size")
fn bit_array_byte_size(bits: BitArray) -> Int
