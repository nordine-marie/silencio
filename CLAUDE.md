# Silencia — repo guide for agents

Silencia is an **iOS** app (Swift 6 / SwiftUI, iOS 16+) that blocks French telemarketing
calls. In France, cold-callers must legally use known Arcep number ranges, so blocking is
**deterministic**, not heuristic. The core is a **CallKit Call Directory extension** that
streams ~12,000,000 blocked numbers to the system.

Product context lives in `docs/` (`product-spec.md`, `implementation-plan.md`, `design/`).
Read those before designing features.

## The one thing to understand about testing this app

Real call *blocking* only works on a physical device — a simulator can't place phone calls.
**But the hard, risky logic is pure Swift and fully testable headless.** That logic lives in
the `SilenciaKit` Swift package: range math, E.164 normalization, the strictly-ascending
memory-bounded blocking-number stream, block-list validation, and the App Group config. Iterate
there with `swift test` (sub-second, no simulator). Only use the simulator to confirm the app
builds, launches, and renders.

## Layout

```
SilenciaKit/          Swift package — ALL pure logic + its XCTest suite (the fast loop)
  Sources/SilenciaKit/
    ArcepRange, RangeData      Arcep prefixes as data (+ bundled ranges.json, validation)
    BlockingRun, BlockingPlan  coalesced disjoint runs → O(1)-memory ascending number stream
    PhoneNumber                French E.164 normalization (numbers + bounded prefixes)
    SharedConfig               App Group bridge the app writes and the extension reads
    BlockEntry, BlockListLogic user block-list entries + add-validation ("déjà couvert", limits)
App/                  SwiftUI app target (the full product; consumes SilenciaKit)
  Core/                      DesignSystem, AppModel, ExtensionBridge (CallKit)
  Features/                  Onboarding (Promise→How→Activation→Success), Dashboard, BlockList, Settings
Blocker/              Call Directory extension target (streams SilenciaKit's plan to CallKit)
project.yml           XcodeGen spec — the .xcodeproj is GENERATED from this, never hand-edited
scripts/              the harness (see below)
docs/                 product spec, implementation plan, design system
```

## Harness commands (prefer these over ad-hoc xcodebuild)

| Command | What it does |
|---|---|
| `scripts/doctor.sh` | Verify toolchain, simulators, project state. Run this first. |
| `scripts/bootstrap.sh` | Install brew tools (xcodegen, xcbeautify, swiftlint, swiftformat) + generate project. One-time. |
| `scripts/test.sh` | **Primary loop.** Headless `swift test` on SilenciaKit. Sub-second. |
| `scripts/test.sh --all` | Also builds the app for the simulator (compiles the iOS targets). |
| `scripts/gen.sh` | Regenerate `Silencia.xcodeproj` from `project.yml` (after editing targets/settings). |
| `scripts/build.sh` | Build the app for the simulator; prints the `.app` path. |
| `scripts/run.sh` | Boot sim → build → install → launch → screenshot. The "see the app" primitive. |
| `scripts/screenshot.sh [out.png]` | Screenshot the booted simulator. |
| `scripts/logs.sh [filter]` | Stream app + extension logs from the booted simulator. |
| `scripts/format.sh` / `scripts/lint.sh` | swiftformat / swiftlint. |

Set a different simulator with `SIM_NAME="iPhone 17 Pro" scripts/run.sh`.

**Screenshotting individual screens:** the simulator has no tap tooling, so Debug
builds accept a launch argument to open any screen directly:
`xcrun simctl launch booted com.silencia.app --screen=<name>` with
`promise | how | activation | success | dashboard | paused | blocklist | settings`
(see `App/Core/DebugScreens.swift`; `paused`/`blocklist` also seed demo state).

## Rules of the road

- **Put logic in `SilenciaKit` with a test.** If a change can be expressed as pure logic
  (anything about *which* numbers block, in what order, under what validation), it belongs in
  the package with an XCTest — not in the app or extension where it can't be tested headless.
- **Never hand-edit `*.xcodeproj`.** Change `project.yml` and run `scripts/gen.sh`. The
  `.xcodeproj` is gitignored and regenerated.
- **The extension must never materialize the number list.** It streams `BlockingPlan.numbers`
  (O(1) memory) and drains an `autoreleasepool` each chunk — the ~6 MB budget is a hard
  constraint (see `implementation-plan.md` §2.3). Preserve the strictly-ascending invariant;
  CallKit rejects out-of-order or duplicate entries. `BlockingPlanTests` guards this.
- **Simulator can't test real blocking.** Device/TestFlight is required for the call-blocking
  matrix in `implementation-plan.md` §2.5. Don't claim blocking "works" from a simulator run.
- **Privacy covenant:** no third-party SDKs, no analytics, no network with personal data.

## Toolchain (verified)

Xcode 26.6 · Swift 6.3 · iOS 26.5 simulator runtime. `scripts/doctor.sh` re-checks live.
