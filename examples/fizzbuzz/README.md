# FizzBuzz over libero RPC

A minimal libero consumer that you can copy as a starting point for your own app. Four `/// @rpc` functions, one Lustre client UI, one tiny session value, no database, no shared package.

## What it shows

The example covers the three return shapes libero handles, the inject pattern, and panic recovery:

- `classify(n) -> String` is a bare-T return with a single arg. Wire envelope on the client is `Result(String, RpcError(Never))`.
- `range(from, to) -> Result(List(String), String)` is a wrapped `Result(T, E)` return with multiple args. The wrong-direction case exercises the `AppError` branch of the error envelope.
- `whoami() -> String` reads a per-connection `client_id` from the Session via a `/// @inject` function. The client stub takes no arguments because the inject parameter never crosses the wire.
- `crash(label) -> String` is a bare-T return that panics on the literal label `"boom"`, exercising libero's `trace.try_call` wrapper and surfacing an `InternalError(trace_id, message)` envelope to the client while logging the matching `PanicInfo` on the server.

## Layout

```
examples/fizzbuzz/
├── server/
│   ├── src/
│   │   ├── server.gleam              # SETUP. Mist HTTP + WS entry point
│   │   └── server/
│   │       ├── fizzbuzz.gleam        # DAY-TO-DAY. /// @rpc functions
│   │       ├── session.gleam         # SETUP. Per-connection Session type
│   │       ├── rpc_inject.gleam      # SETUP. /// @inject functions
│   │       ├── websocket.gleam       # SETUP. Builds Session, calls dispatch
│   │       └── web.gleam             # SETUP. Static file serving
│   └── priv/static/index.html        # loads the compiled Lustre bundle
├── client/
│   └── src/
│       ├── client.gleam              # SETUP. Lustre entry point
│       └── client/app.gleam          # DAY-TO-DAY. model / update / view
└── bin/dev                           # regenerate, build, start
```

Files marked **SETUP** are the one-time wiring you write when you first stand up a libero project and rarely touch again. Files marked **DAY-TO-DAY** are where you actually add features: define a new `/// @rpc` server function in `fizzbuzz.gleam`, then call its generated stub from `client/app.gleam`. Everything in between is generated.

After the first `bin/dev` run, libero adds two generated subtrees that aren't in the source checkout:

```
server/src/server/generated/libero/rpc_dispatch.gleam
client/src/client/generated/libero/rpc_config.gleam
client/src/client/generated/libero/rpc/fizzbuzz.gleam
```

These are regenerated on every `bin/dev` run from the `/// @rpc` functions in `server/src/server/**`. Don't edit them by hand.

## Run it

```bash
./bin/dev
```

Then open <http://localhost:4000>. Each section drives one of the four RPCs:

1. **Classify** sends a number, gets back its FizzBuzz label.
2. **Range** sends two numbers; try `from=10, to=1` to see the `AppError` branch fire.
3. **Whoami** takes no input; the server returns the `client_id` it generated for your WebSocket connection. Refresh the page to get a new one.
4. **Crash** with the label `"boom"` triggers a server panic and exercises the `InternalError(trace_id, message)` envelope plus the matching server log.

## The server surface

```gleam
// server/src/server/fizzbuzz.gleam

import gleam/int

/// @rpc
pub fn classify(n n: Int) -> String {
  case int.modulo(n, 3), int.modulo(n, 5) {
    Ok(0), Ok(0) -> "FizzBuzz"
    Ok(0), _ -> "Fizz"
    _, Ok(0) -> "Buzz"
    _, _ -> int.to_string(n)
  }
}

/// @rpc
pub fn range(from from: Int, to to: Int) -> Result(List(String), String) {
  case from <= to {
    False -> Error("from must be <= to")
    True -> Ok(build_labels(current: to, from: from, acc: []))
  }
}

/// @rpc
pub fn whoami(client_id client_id: String) -> String {
  "you are client " <> client_id
}

/// @rpc
pub fn crash(label label: String) -> String {
  case label {
    "boom" -> panic as "you asked for it"
    _ -> "no boom"
  }
}
```

The `/// @rpc` doc comment tells libero to expose the function to the client. Wire format, dispatch routing, client stub, and error envelope are all generated from the signature. The first labelled parameter of `whoami` is `client_id`, which matches the inject function below, so the server pulls the value out of the Session and the client never sends it.

## The inject function

```gleam
// server/src/server/rpc_inject.gleam

import server/session.{type Session}

/// @inject
pub fn client_id(session: Session) -> String {
  session.client_id
}
```

Any `@rpc` function whose first labelled parameter is named `client_id` (with type `String`) gets this value passed in automatically at dispatch time. Inject parameters never appear on the wire; the client stub for `whoami` takes no wire arguments at all.

## The session

```gleam
// server/src/server/session.gleam

pub type Session {
  Session(client_id: String, connected_at_unix: Int)
}
```

`websocket.gleam` builds one of these per connection at WebSocket `init` time, stores it in the connection state, and hands a fresh `Session` value to `rpc_dispatch.handle` on every incoming message. Real apps typically carry a DB connection, an authenticated user, a tenant id, etc. The shape is up to you; libero only cares that all `@inject` functions in a namespace agree on a single `Session` type.

If you don't need a session at all, omit the `@inject` functions entirely. Libero will pick `Session = Nil` and the generated dispatch will accept `session: Nil`.

## The client call

```gleam
// client/src/client/app.gleam  (snippet)

import client/generated/libero/rpc/fizzbuzz as rpc_fizzbuzz

// ...

Classify ->
  #(
    model,
    rpc_fizzbuzz.classify(n: 42, on_response: ClassifyResponse),
  )

WhoamiSubmitted ->
  #(
    model,
    rpc_fizzbuzz.whoami(on_response: WhoamiResponse),
  )
```

Each stub is type-safe. `rpc_fizzbuzz.classify` takes `n: Int` and responds with `Result(String, RpcError(Never))`. `rpc_fizzbuzz.whoami` takes no wire arguments because `client_id` is injected on the server. The compiler checks that your message handler covers the full response envelope.

## What libero doesn't do

Libero has no caching, no retries, and no optimistic updates. That's your model's job.

Libero has no subscriptions. RPCs are strict request/response. If you need push updates, layer a separate mechanism on top.

Libero has no state-management opinions. It hands you `Effect(msg)` with a typed response. Whether you wrap it in `RemoteData`, handle it as `Result`, or something else is entirely up to your app.
