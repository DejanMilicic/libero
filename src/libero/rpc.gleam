//// Client-side send machinery.
////
//// `send` is the entry point used by libero-generated client stubs.
//// It takes the WebSocket URL, the module name, and the typed ToServer
//// message to deliver.
////
//// The JS FFI (rpc_ffi.mjs) opens the WebSocket lazily on first call
//// and caches the connection. Sends issued before the socket is open
//// are queued and flushed on the open event.
////
//// Developers don't usually call this module directly. They import
//// the per-module stubs the libero generator writes into their
//// client package, and those stubs delegate here.

import lustre/effect.{type Effect}

/// Send a typed ToServer message to the server via WebSocket.
/// Used by generated client send stubs.
///
/// The `module` parameter identifies which shared module the message
/// belongs to (e.g. `"shared/todos"`). The server dispatch routes
/// by this name to the correct handler.
pub fn send(
  url url: String,
  module module: String,
  msg msg: a,
) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    ffi_send(url:, module:, msg:)
  })
}

@external(javascript, "./rpc_ffi.mjs", "send")
fn ffi_send(
  url url: String,
  module module: String,
  msg msg: a,
) -> Nil {
  let _ = url
  let _ = module
  let _ = msg
  panic as "libero/rpc is a JavaScript-only module, unreachable on Erlang target"
}
