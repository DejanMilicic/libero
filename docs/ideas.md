# Ideas

## ~~`libero new --database sqlite`~~ ✓ Implemented

Shipped in v4.2. `--database pg` and `--database sqlite` are supported.
See `cli.gleam` and `cli/templates/db.gleam`.

## Future ideas

- Type alias walk-through in walker (currently skips aliases silently)
- Request IDs in wire protocol (see below)
- Reconnection strategy for push handlers (currently consumer responsibility)

## Request IDs in wire protocol

**Problem:** Response matching currently uses FIFO order — the client
assumes responses arrive in the same order requests were sent. This works
because the server processes requests sequentially over a single
WebSocket. But if a handler panics, `dispatch` catches the panic and
returns an `InternalError` response for that request. The FIFO assumption
holds even under panics today.

The fragile case: if the server were to *drop* a response entirely (e.g.
the WebSocket handler crashes between dispatch and send, or mist fails to
flush the frame), every subsequent callback would receive the wrong
response with no detection. Silent data corruption.

**Proposal:** Add an incrementing request ID to the wire envelope. The
client assigns a monotonic counter to each `send()` call and includes it
in the ETF payload. The server echoes the ID back in the response frame.
The client matches responses by ID instead of FIFO position.

**Wire format change:**

```
Current call:   {module_binary, msg_from_client_value}
Proposed call:  {module_binary, request_id_int, msg_from_client_value}

Current response: <<tag, etf_bytes>>
Proposed response: <<tag, request_id:32, etf_bytes>>
```

**Why deferred:** This is a breaking wire protocol change. Both client and
server must be updated together, and any in-flight connections during a
rolling deploy would see mismatched formats. Should ship as part of a
major version bump (v5) with a migration guide.

**Scope:**
- `rpc_ffi.mjs`: add counter to `send()`, match by ID in message handler
- `wire.gleam`: update `encode_call` / `decode_call` to include request ID
- `codegen.gleam`: update generated dispatch to echo the ID
- Tests: wire roundtrip tests, rpc integration tests
