import gleam/erlang/process
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/string
import libero/wire
import mist
import server/generated/libero/dispatch
import server/shared_state.{type SharedState}

pub type State {
  State(shared: SharedState)
}

pub fn on_init(shared: SharedState) {
  fn(_conn: mist.WebsocketConnection) -> #(State, Option(process.Selector(Nil))) {
    io.println("[ws] client connected")
    #(State(shared:), None)
  }
}

pub fn handler(
  state: State,
  message: mist.WebsocketMessage(Nil),
  conn: mist.WebsocketConnection,
) -> mist.Next(State, Nil) {
  case message {
    mist.Binary(data) -> {
      io.println("[ws] raw bytes: " <> string.inspect(data))
      case wire.decode_call(data) {
        Ok(#(module, msg)) ->
          io.println("[ws] recv " <> module <> ": " <> string.inspect(msg))
        Error(err) ->
          io.println("[ws] decode error: " <> string.inspect(err))
      }
      let #(response_bytes, maybe_panic, new_shared) =
        dispatch.handle(state: state.shared, data:)
      case maybe_panic {
        Some(info) ->
          io.println("[ws] PANIC: " <> string.inspect(info))
        None -> Nil
      }
      let _ = mist.send_binary_frame(conn, response_bytes)
      mist.continue(State(shared: new_shared))
    }
    mist.Closed | mist.Shutdown -> {
      io.println("[ws] client disconnected")
      mist.stop()
    }
    mist.Text(_) -> mist.continue(state)
    mist.Custom(_) -> mist.continue(state)
  }
}
