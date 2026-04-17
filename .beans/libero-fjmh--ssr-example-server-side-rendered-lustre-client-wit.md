---
# libero-fjmh
title: 'SSR example: server-side rendered Lustre client with hydration'
status: draft
type: feature
priority: low
created_at: 2026-04-17T01:45:50Z
updated_at: 2026-04-17T01:45:50Z
---

Create an example app demonstrating SSR with Libero:

- Server calls dispatch.handle() directly to fetch initial data (no WebSocket round-trip)
- Renders shared Lustre view functions on the BEAM via lustre/element.to_string()
- Embeds model state as flags in the HTML response
- Client-side Lustre boots with flags, hydrates onto existing DOM, skips initial RPC
- WebSocket connects for subsequent interactions

Key things to validate:
- Shared view functions compile to both Erlang and JS targets
- dispatch.handle() works cleanly as a direct call for SSR
- Flags serialization/deserialization round-trips correctly
- Hydration is seamless (no flash of re-render)
