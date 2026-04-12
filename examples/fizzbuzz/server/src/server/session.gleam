//// SETUP. Extend when you add new fields the server needs to keep
//// per connection (e.g. an authenticated user, a tenant id, a db
//// handle).
////
//// Per-connection session value.
////
//// One Session is constructed when a WebSocket client connects and is
//// then passed into every libero RPC dispatch on that connection. The
//// type is intentionally simple (read-only, no actors, no mutation),
//// because the goal is to demonstrate libero's `/// @inject` plumbing,
//// not to be a fully-featured session store.
////
//// `client_id` is a short random identifier the server hands the
//// connection at init time. The `whoami` RPC echoes it back via the
//// inject function in `rpc_inject.gleam`.
////
//// In a real app this is where you'd put a database connection, an
//// authenticated user, a tenant id, a request scope, etc. The shape
//// is up to you. Libero only cares that all `@inject` functions in a
//// namespace agree on a single `Session` type.

pub type Session {
  Session(client_id: String, connected_at_unix: Int)
}
