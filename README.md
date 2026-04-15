# Libero

Libero generates typed WebSocket plumbing between a Gleam server and a Lustre client. You define message types in a shared module, and libero produces a server dispatch function and client send stubs from them. No REST routes, no JSON codecs, no hand-written dispatch tables.

## Convention

Every shared module that participates in libero's codegen exports two types by convention:

```gleam
// shared/src/shared/todos.gleam

pub type ToServer {
  Create(params: TodoParams)
  Toggle(id: Int)
  Delete(id: Int)
  LoadAll
}

pub type ToClient {
  Created(Todo)
  Toggled(Todo)
  Deleted(id: Int)
  AllLoaded(List(Todo))
  Error(TodoError)
}
```

`ToServer` contains messages the client sends to the server. `ToClient` contains messages the server pushes back to the client. A module can define one or both.

## Example usage

The client sends a message using the generated stub:

```gleam
// In your Lustre update:
import client/generated/libero/todos as todos_rpc

ToggleTodo(id) ->
  #(model, todos_rpc.send(Toggle(id:)))
```

The server handles it in the handler module:

```gleam
// server/src/server/handlers/todos.gleam

import shared/todos.{type ToServer}
import server/shared_state.{type SharedState}
import server/app_error.{type AppError}

pub fn handle(msg msg: ToServer, state state: SharedState) -> Result(Nil, AppError) {
  case msg {
    todos.Create(params:) -> create_todo(state.db, params)
    todos.Toggle(id:) -> toggle_todo(state.db, id)
    todos.Delete(id:) -> delete_todo(state.db, id)
    todos.LoadAll -> load_all(state.db, state.conn)
  }
}
```

The server pushes `ToClient` messages back to the client over the same WebSocket connection via the `SharedState`.

See [`examples/todos/`](./examples/todos/) for a complete runnable example.

## CLI usage

Run from your server package directory:

```bash
cd server
gleam run -m libero -- \
  --ws-url=wss://your.host/ws \
  --shared=../shared \
  --server=.
```

Or for multi-tenant deployments where the hostname varies:

```bash
gleam run -m libero -- \
  --ws-path=/ws \
  --shared=../shared \
  --server=.
```

### Flags

- `--ws-url=<url>` or `--ws-path=<path>` (one required): hardcodes a full URL or resolves it at runtime from `window.location`.
- `--shared=<path>`: path to the shared package root.
- `--server=<path>`: path to the server package root.
- `--client=<path>`: path to the client package root (defaults to `../client`).
- `--namespace=<name>`: optional prefix for multi-SPA setups.
- `--write-inputs`: write a `.inputs` manifest for staleness checks.

## What gets generated

From a shared module at `shared/src/shared/todos.gleam`, libero writes:

- `server/src/server/generated/libero/dispatch.gleam`: routes incoming wire calls to handler modules.
- `client/src/client/generated/libero/todos.gleam`: typed `send` stub for the client.
- `client/src/client/generated/libero/rpc_config.gleam`: WebSocket URL configuration.
- `client/src/client/generated/libero/rpc_register.gleam` + `rpc_register_ffi.mjs`: registers every custom type that may appear on the wire so the client can reconstruct ETF terms.

## How it works

The wire format is Erlang External Term Format (ETF) over binary WebSocket frames. Gleam's custom types, lists, options, and primitives all serialize reflectively without explicit codecs.

The client sends a `{module_path, ToServer_value}` tuple. The server dispatch decodes it, routes by module path, calls the handler, and the handler uses `SharedState` to push `ToClient` messages back.

The generator scans shared modules for `ToServer` and `ToClient` types, walks their type graphs transitively to find all types that need codec registration, and emits the dispatch and stub files.

## License

MIT. See [LICENSE](https://github.com/pairshaped/libero/blob/master/LICENSE).
