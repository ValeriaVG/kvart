[![App Store](https://img.shields.io/badge/App%20Store-Available%20on%20the%20App%20Store-blue?logo=app-store&style=flat-square)](https://apps.apple.com/se/app/kvart/id6754662969?l=en-GB)

# Kvart

Kvart (from Swedish "kvart", meaning "quarter") is a visual timer app built with a Rust [Crux](https://redbadger.github.io/crux/) core and a native iOS (SwiftUI) shell.
It does one thing and does it well: it helps you keep track of time in set intervals.

![Screenshot: round green timer set to 15 minutes](./screenshots/IMG_5167.jpeg)

[More screenshots](./screenshots/)

## Distribution
Kvart is available on the [Apple App Store](https://apps.apple.com/se/app/kvart/id6754662969?l=en-GB) for iOS devices and can be downloaded for free.

Android version is planned for the near future.

App contains in-app purchases to unlock additional themes for a minimal one-time fee to support development.

## Development

Kvart combines a shared Rust core (using [Crux](https://redbadger.github.io/crux/)) with a native iOS shell. The core owns all domain logic, state, and view projections; the shell stays thin with native views and capabilities.

### Prerequisites

- [Rust](https://www.rust-lang.org/tools/install) with the `wasm32-unknown-unknown` target (`rustup target add wasm32-unknown-unknown`)
- [just](https://github.com/casey/just) task runner
- [xcodegen](https://github.com/yonaskolb/XcodeGen) and [cargo-swift](https://github.com/antoniusnaumann/cargo-swift) v0.9.0
- Xcode with iOS Simulator — follow [Apple's setup guide](https://developer.apple.com/xcode/) for your iOS development environment

### Layout

- `./shared` — Rust/Crux core (domain types, events, pure `handle()` logic, view models)
- `./apple` — iOS SwiftUI shell consuming the generated Swift bindings

### Running

From `./shared`, validate and test the core:

```bash
just dev   # fix → check → build → test
```

From `./apple`, generate bindings, build, and run on the iOS Simulator:

```bash
just generate   # typegen → package → xcodegen
just build      # xcodebuild for the Kvart scheme
```

See [`CLAUDE.md`](./CLAUDE.md) for the full core-first workflow and conventions.

## Support

Kvart is free and open source software, if you find it useful you could consider supporting its development: 

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/valeriavg).

