//// SETUP. Write once, leave alone.
////
//// This is the connection-lifecycle code that wires libero into mist.
//// In a real app you write this once and forget about it.
////
//// Per connection:
////
////   1. `init` runs once, generates a `client_id`, captures the
////      connect time, and stashes both in `State`.
////   2. Every text frame on this connection runs `handle_message`,
////      which builds a fresh `Session` from State and hands it to
////      libero's generated `rpc_dispatch.handle`.
////   3. Dispatch routes the call into the right `@rpc` function,
////      pulling injected values (like `client_id`) out of the
////      Session via the `@inject` functions in `rpc_inject.gleam`.
////
//// `handle` returns the wire response and an `Option(PanicInfo)`.
//// If a server fn panicked, the panic info bubbles out so we can log
//// it server-side while the client receives an opaque trace_id. The
//// WebSocket connection is never dropped on bad input or panics.

import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/time/timestamp
import libero/error.{type PanicInfo, PanicInfo}
import mist.{type WebsocketConnection, type WebsocketMessage}
import server/generated/libero/rpc_dispatch
import server/session.{Session}

pub type State {
  State(client_id: String, connected_at_unix: Int)
}

pub fn init(
  _ws_conn: WebsocketConnection,
) -> #(State, Option(process.Selector(Nil))) {
  let client_id = generate_client_id()
  let #(now_unix, _) =
    timestamp.system_time() |> timestamp.to_unix_seconds_and_nanoseconds()
  #(State(client_id: client_id, connected_at_unix: now_unix), None)
}

pub fn handle_message(
  state: State,
  message: WebsocketMessage(Nil),
  conn: WebsocketConnection,
) -> mist.Next(State, Nil) {
  case message {
    mist.Text(text) -> {
      // Build the per-call Session out of our connection State and
      // hand it to libero's generated dispatch. Libero pulls inject
      // values (like `client_id`) out of this Session for any RPC
      // function that asks for them.
      let session =
        Session(
          client_id: state.client_id,
          connected_at_unix: state.connected_at_unix,
        )
      let #(response_text, maybe_panic) =
        rpc_dispatch.handle(session: session, text: text)
      log_panic(maybe_panic)
      let _ = mist.send_text_frame(conn, response_text)
      mist.continue(state)
    }
    mist.Binary(_) -> mist.continue(state)
    mist.Closed | mist.Shutdown -> mist.stop()
    mist.Custom(_) -> mist.continue(state)
  }
}

/// A 6-digit pseudo-random identifier. Good enough for a demo, not
/// good enough for anything that needs uniqueness or unguessability.
fn generate_client_id() -> String {
  int.random(900_000) + 100_000
  |> int.to_string
}

fn log_panic(info: Option(PanicInfo)) -> Nil {
  case info {
    Some(PanicInfo(trace_id: trace_id, fn_name: fn_name, reason: reason)) ->
      io.println_error(
        "libero panic trace_id="
        <> trace_id
        <> " fn="
        <> fn_name
        <> " reason="
        <> reason,
      )
    None -> Nil
  }
}
