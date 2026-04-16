---
# libero-77nq
title: Version mismatch detection
status: todo
type: feature
priority: normal
created_at: 2026-04-16T00:45:06Z
updated_at: 2026-04-16T03:05:15Z
---

Detect client/server version drift and trigger a client reload instead of silent decode failures.

Approach: libero codegen computes a hash of the shared module types (e.g., hash of all MsgFromClient/MsgFromServer type signatures discovered by the walker). This hash is embedded in both the generated client JS and the server dispatch module.

On the first WebSocket response, the server includes its hash in the response envelope. The client compares it against its own embedded hash. If they diverge, the client forces a page reload instead of attempting to decode with stale constructors.

Implementation:
1. Walker outputs a type graph hash alongside the discovered variants
2. Codegen embeds the hash in the generated dispatch module and client stubs
3. Wire protocol: first response includes a version field (or a one-time handshake frame)
4. rpc_ffi.mjs checks the hash on first response and calls location.reload() on mismatch

Alternative lighter approach: skip the hash and just cache-bust the JS bundle with content hashes in filenames. Most deployment setups already handle this, making libero-level detection unnecessary.
