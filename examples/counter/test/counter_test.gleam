import gleeunit
import server/handler
import server/shared_state
import shared/messages.{CounterUpdated, Decrement, GetCounter, Increment}

pub fn main() {
  gleeunit.main()
}

fn fresh_state() -> shared_state.SharedState {
  shared_state.new()
}

pub fn get_counter_returns_zero_initially_test() {
  let state = fresh_state()
  let assert Ok(#(CounterUpdated(Ok(0)), _)) =
    handler.update_from_client(msg: GetCounter, state:)
}

pub fn increment_returns_one_test() {
  let state = fresh_state()
  let assert Ok(#(CounterUpdated(Ok(1)), _)) =
    handler.update_from_client(msg: Increment, state:)
}

pub fn decrement_returns_negative_one_test() {
  let state = fresh_state()
  let assert Ok(#(CounterUpdated(Ok(-1)), _)) =
    handler.update_from_client(msg: Decrement, state:)
}

pub fn increment_then_decrement_returns_zero_test() {
  let state = fresh_state()
  let assert Ok(#(CounterUpdated(Ok(1)), state)) =
    handler.update_from_client(msg: Increment, state:)
  let assert Ok(#(CounterUpdated(Ok(0)), _)) =
    handler.update_from_client(msg: Decrement, state:)
}
