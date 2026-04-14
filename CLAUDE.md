# Kvart

Visual timer app.
Combines `./shared` (Rust/Crux core) and `./apple` (iOS shell).

## Development Approach

Offload everything possible to the core. The shell stays thin: native views and native capabilities only. Each iteration must leave the app in a working, device-testable state.

For any new feature, work core-first, inside-out:

1. **Types** — domain models in `shared/src/<domain>/`
2. **Events** — variants on the domain's own event enum (name it `<Domain>Event`, not `Event`, so facet typegen doesn't generate self-colliding Swift cases when the root enum nests it)
3. **Tests** — pure unit tests against `handle()` before any shell work
4. **Wire-up** — compose into `app.rs` root `Event`/`Model`/`ViewModel`, regenerate Swift types, then build shell views

Strive towards plain shell views with previews.

Each domain module owns its types, events, pure `handle()`, seed data, `Default` impls, and shell-facing view projection (e.g. `TimerView` lives in `shared/src/timer/`). `app.rs` only composes — no per-domain defaults or view conversions there. Keep domains free of `crux_core` imports; they should be plain Rust.

Avoid Rust variant names that are Swift reserved words (`Default`, `class`, etc.) — they'll break the generated Swift. Rename in core rather than post-processing.

## Shell type bindings

Facet typegen converts Rust `snake_case` struct fields to `camelCase` in Swift (`seconds_total` → `secondsTotal`). After `just typegen`, grep `apple/generated/App/Sources/App/App.swift` to confirm the generated names.

## Build System

[just](https://github.com/casey/just) task runner per subproject, with shared `lib.just`.

### shared (Rust core) — run from `./shared`
- `just fix` — `cargo fmt`
- `just check` — fmt + clippy (native + `wasm32-unknown-unknown`)
- `just build` / `just test` / `just dev` (fix → check → build → test)

### apple (iOS shell) — run from `./apple`
- `just fix` / `just check` — swiftlint
- `just typegen` — Swift types via the `codegen` binary
- `just package` — builds `shared` as a static Swift package via `cargo-swift` v0.9.0
- `just generate-project` — regenerates `Kvart.xcodeproj` from `project.yml` via `xcodegen`
- `just generate` — typegen → package → generate-project
- `just build` — generate → `xcodebuild` (scheme `Kvart`, config `Debug`, iOS Simulator)
- `just dev` — fix → check → build → test
