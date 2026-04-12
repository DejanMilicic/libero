# Feedback

A running log of issues, gotchas, and improvement ideas hit while using libero in real projects. This is the intake queue for libero evolution — entries here become issues, PRs, and changelog entries over time.

The first batch of entries comes from the Curling IO v3 SPA port (late 2026), where libero is consumed as a git submodule and used to wire the admin panel's RPC layer. Future entries should come from any consumer that hits something surprising or time-wasting.

Add to this file whenever you hit something surprising, time-wasting, or improvable about libero. Keep entries short — one paragraph plus a severity tag.

Severity tags:
- **BLOCKING** — stops forward progress until worked around
- **HIGH** — causes lost time or confusion every time it happens
- **MEDIUM** — annoying but not time-consuming
- **LOW** — nice-to-have polish

## Known issues

### 1. ~~Libero hangs at 99% CPU after code generation~~ FIXED

The success path in `main()` returned `Nil` without calling `halt(0)`. The BEAM VM stays alive when `main` returns if any OTP processes or schedulers are running. Added `halt(0)` on the success path to match the error path's `halt(1)`.

### 2. ~~`--ws-url` parameter on a code generator is confusing~~ FIXED

Clarified CLI help text, generated config comments, and README to make it clear that `--ws-url` is the client's runtime WebSocket endpoint, not a generator input. Libero does not connect to this URL; it writes it into the generated `rpc_config.gleam`.

### 3. ~~Silent failure when @inject label doesn't match~~ FIXED

When a Wire parameter's rendered type matches an `@inject` function's return type but the label doesn't match, libero now emits a `LikelyInjectTypo` error with a suggested fix. This catches typos like `tzdb` vs `tz_db` at generation time instead of producing silently wrong code.

### 4. ~~`InternalError(trace_id)` is opaque to the client~~ FIXED

Added a `message: String` field to `InternalError`, populated with a default client-safe string ("Something went wrong, please try again.") in the generated dispatch. Consumers can pattern-match on `message` to show users something meaningful without leaking trace IDs or stack traces into the UI.

### 5. ~~Killing parent build doesn't always kill libero child process~~ FIXED

Root cause was #1 (missing `halt(0)` on success). Additionally, `main()` now installs SIGTERM and SIGHUP handlers via a spawned Erlang signal loop that calls `halt(1)` on receipt, so libero exits cleanly even when killed mid-generation.

### 6. ~~Dependency invalidation is consumer-managed~~ FIXED

Added `--write-inputs` flag: when passed, libero writes a `.inputs` manifest listing every source file it scanned (one per line, sorted). Consumer build scripts can diff this against a stamp file for reliable staleness checks. Also documented the manual watch list approach in the README's "Build integration" section.

### 7. ~~`LikelyInjectTypo` check is too aggressive~~ FIXED

The type-only check from issue #3 now also requires the label to be within Levenshtein distance 2 of the inject function's name. This catches real typos (`tzdb`/`tz_db` = distance 1) while ignoring unrelated labels that happen to share a common type (`key`/`lang` = distance 3+).

### 8. `--ws-url` bakes a subdomain into the compiled client (BLOCKING for multi-tenant consumers)

**Symptom:** Libero takes `--ws-url=wss://demo.curling.dev/ws/admin` at generation time and writes it as a compile-time constant into `rpc_config.gleam`. Consumers that run multi-tenant subdomain-based deployments (e.g. `foo.curling.io`, `bar.curling.io` sharing one compiled admin bundle) cannot use this: every compiled client is locked to one specific subdomain.

**Impact:** The Curling IO v3 consumer is multi-tenant — 200+ orgs each have their own subdomain. One compiled JS bundle is served to all of them. Right now the bundle hardcodes `wss://demo.curling.dev/ws/admin`, which means every org except `demo` would try to connect to the wrong host. This is a production blocker, not a dev annoyance.

**Suggestion:** Libero should accept a **path-relative** URL (e.g. `--ws-path=/ws/admin`) and have the generated client runtime build the full URL at connect time via `wss://${window.location.host}${path}`. The scheme (ws vs wss) can also be inferred from `window.location.protocol` (http → ws, https → wss). Keep `--ws-url` as a compat alias but document it as "for single-host deployments only; use --ws-path for multi-tenant."

Alternatively/additionally: generate the client with a runtime setter so consumers can configure the URL from an application-provided source (e.g. a JSON blob in the HTML shell, similar to how the Curling v3 admin shell already ships session data).

**Workaround:** the consumer can rewrite the generated `rpc_config.gleam` after generation, or patch the runtime `rpc_ffi.mjs` to ignore the baked URL. Both are hacks.

### 9. Walker hangs silently when consumer has name-colliding variants across shared modules (BLOCKING)

**Symptom:** With libero v2.0.0 + 02d273f, running libero against a consumer that has two shared modules with identically-named variant constructors causes the walker to hang silently between "wrote rpc_config.gleam" and the "register: N variants" line. The process enters sleeping state (blocked in `do_select`), is not CPU-spinning, and has no visible progress output. No error, no panic, no crash — just stops.

**Reproducer (minimal):** The Curling IO v3 consumer has `shared/discount.gleam` and `shared/fee.gleam`, both of which declare `DatabaseError(String)`, `NameRequired`, and `InvalidAgeRange` as variant constructors on their respective error types. When only one of these is reachable from an `@rpc` function, the walker completes normally. When both are reachable, the walker hangs.

**Bisect result:**
- `discounts.*` enabled alone → works (37 variants discovered)
- `fees.*` enabled alone → works (8 variants discovered)
- `discounts.*` + `fees.*` together → hangs indefinitely

**Impact:** This blocked v3 regeneration entirely. The consumer can't port sections that share a colliding variant name with any other ported section's error/params type.

**Hypothesis:** Either (a) the walker's visited-set deduplication is keyed only on `type_name` and a second visit with the same type_name from a different module_path triggers an infinite re-processing loop, or (b) the dispatch code generation is looking up variants by atom (via `to_snake_case(variant_name)`) and the collision causes a lookup to stall. The first hypothesis seems more likely given that the hang happens BEFORE dispatch writes (it's inside `write_register` → `walk_registry_types`).

**Suggestion:** Audit `do_walk` / `process_type_ast` / `collect_variant_field_refs` for correctness in the presence of duplicate variant names across different modules. Each `(module_path, type_name)` tuple is a unique visited entry; no variant name should ever cause a re-visit because the tuples differ. If the collision is tripping something up, it's in the registration step, not the walker — maybe duplicate atom registration is attempting to deduplicate via an iteration that doesn't terminate.

**Ideally libero should also warn on atom collisions** like the three above. Two modules emitting `database_error` to the same atom table is a consumer bug (or at least a smell) that libero could surface at generation time rather than silently hanging.

**Workaround:** Rename the colliding variants. The Curling v3 consumer already uses prefixed variants in every section *except* the two oldest ones (`DiscountError`, `FeeError`) — renaming `fee.DatabaseError` → `fee.FeeDatabaseError` and similar is also an independent consistency improvement.

## Ideas for future libero capabilities

### Structured deprecation support

As `@rpc` signatures evolve during a large port, consumers occasionally change a signature without immediately updating every generated client (e.g. during a refactor). Libero could support `@deprecated("message")` on `@rpc` functions and generate a warning in the client stubs.

### Typed dispatch mode

Libero currently generates a single `handle_<namespace>` function that takes binary data. This works but means every dispatch is a runtime binary decode. A typed dispatch mode (one Gleam function per `@rpc` that takes decoded params and returns encoded result) would be useful for testing: consumers could call the RPC layer directly in tests without going through the binary encoder/decoder.

### Test helpers

Every `@rpc` function tends to want integration tests on the consumer side. Libero could generate test fixtures — e.g. a mock session builder, a way to call RPCs with decoded params directly, and a way to assert on the response shape.

### Schema snapshot for client-generated types

Libero walks the `@rpc` type graph and generates registration code so the client can decode all referenced types. If the server's type graph changes (e.g. adding a variant to a shared error type), the client needs a full regen. A schema snapshot file that libero compares against would catch drift at CI time instead of runtime.

### Helper extraction for per-section boilerplate

Consumers building typical admin CRUD sections end up writing the same `rpc_error_to_string` pattern in every section: unwrap `AppError(e)` / `InternalError(trace_id)` / `UnknownFunction(name)` / `MalformedRequest` into a string. Libero could emit a helper that handles the non-app cases uniformly so consumers only write the `AppError(e)` branch.

## Adding to this doc

When you hit something, add an entry above the "Ideas for future libero capabilities" section with:
- A short title ending in `(SEVERITY)`
- **Symptom:** what you observed
- **Impact:** what it cost (if non-obvious)
- **Hypothesis** or **Workaround** if you have one
- **Suggestion** if you have one

Keep entries grounded in what actually happened — speculation is fine but mark it as hypothesis.
