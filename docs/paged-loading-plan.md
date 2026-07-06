# Silencia — Paged Call Directory Loading: Spec & Implementation Plan

**Version:** 1.0
**Date:** July 2026
**Companion docs:** `product-spec.md`, `implementation-plan.md` (supersedes its §2.3 code sample and §2.4)
**Status:** Approved for implementation

---

## 1. Problem

Enabling the SilenciaBlocker extension on a physical device fails with the system alert
*« The data provided by Silencia was invalid »*. Captured device log (iPhone 16 Pro, iOS 26,
2026-07-06):

```
com.apple.CallKit.CallDirectory <Error>: Cannot add entries since it would exceed
maximum allowed entries (2000000), returning error
…
Error Domain=com.apple.CallKit.error.calldirectorymanager Code=5   // maximumEntriesExceeded
```

The extension itself behaves exactly as designed — it streams all entries in ascending order
under the memory budget and completes (`[SilenciaBlocker] emitted 12000000 blocking entries`,
no jetsam kill). CallKit rejects the *request* because it added more than **2,000,000 entries
in a single `beginRequest` pass**. The whole request is rolled back transactionally: the store
ends up empty and the enable toggle bounces back.

### 1.1 The constraint, precisely

- **2,000,000 is a per-request cap, not a total-store cap.** Each `beginRequest` invocation may
  add at most 2M entries. The store itself accumulates across incremental requests.
- Proof by existing apps: Begone loads ~24.5M numbers, Saracroche ~15M — both far past 2M, both
  via a single Call Directory extension.
- Saracroche is GPL and confirms the mechanism ([codeberg.org/cbouvat/saracroche-ios](https://codeberg.org/cbouvat/saracroche-ios)):
  the **app drives a loop of `reloadExtension` calls**; each `beginRequest` runs in incremental
  mode and adds one slice; slices accumulate in the system store.
- CallKit has no range/prefix API — every number is one entry. 12 Arcep ranges × 10⁶ = 12M
  entries, incompressible.
- Within one request, entries must be strictly ascending (existing invariant, unchanged).
  Across incremental requests, each new request merges into the existing store.
- The simulator **does not enforce the cap** — this failure mode only exists on device.

### 1.2 Why we don't copy Saracroche's implementation

Saracroche materializes each slice as an array of number-strings pushed through shared
UserDefaults, capped at 10,000 numbers per round → ~1,500 reload rounds for 15M numbers, very
slow first load, and the materialized arrays waste the extension's memory budget. Silencia
already has the right core: `BlockingPlan.numbers` generates the ascending stream from
coalesced runs in **O(1) memory**. We keep generation inside the extension and page it with a
cursor — pages of ~1.8M, **7 rounds** for the full set, zero materialization.

## 2. Design overview

```
App (foreground)                          App Group                    Extension (per beginRequest)
────────────────                          ─────────                    ────────────────────────────
                                          config.json  ──────────────▶ plan = SharedConfig.plan()
syncExtension():                                                       state = LoaderState.load()
  repeat until complete:                  loader-state.json ─────────▶ action = PagedLoader.nextAction(
    bridge.reload()  ────────────────────────────────────────────────▶   isIncremental, state, plan)
    (completion = round finished)                                      emit ≤ PAGE_SIZE entries
    read LoaderState ◀──────────────────  loader-state.json ◀───────── save advanced LoaderState
    publish progress (x / 12 000 000)                                  completeRequest()
```

- The **extension** stays a dumb, deterministic streamer: on every invocation it computes
  *which page comes next* from persisted state, emits at most `PAGE_SIZE` entries, advances the
  cursor, completes.
- The **app** is the driver: it calls `reloadExtension` in a loop until the persisted state says
  the current plan is fully loaded. Every round's completion handler tells the app whether the
  round committed.
- **All decision logic is pure Swift in `SilenciaKit`** (`PagedLoader`, `LoaderState`), fully
  unit-tested headless — per the repo rule that anything about *which numbers block, in what
  order* lives in the package.

### 2.1 Page size

| Constant | Value | Rationale |
|---|---|---|
| `PagedLoader.systemMaxEntriesPerRequest` | `2_000_000` | Observed hard limit (device log §1) |
| `PagedLoader.pageSize` | `1_800_000` | 10% headroom under the cap; 12.5M worst case (12M Arcep + 0.5M custom cap) → **7 pages** |

Page emission cost is small: the single-pass attempt emitted 12M entries in ~31 s on an
iPhone 16 Pro → ~4.6 s per page + ~1–2 s reload overhead → full load ≈ **45–60 s** on modern
hardware, a few minutes on the floor device (iPhone SE 2020). Each round is short enough that
per-request watchdogs and the memory budget are non-issues (memory discipline is unchanged:
streamed generation + `autoreleasepool` every 100k).

### 2.2 Loader state (App Group)

New file `loader-state.json` beside `config.json`. **Written by the extension, read by the app**
(the app only ever deletes it, to force a full rebuild). Ownership stays disciplined:
`config.json` app→extension, `loader-state.json` extension→app.

```json
{
  "schemaVersion": 1,
  "planFingerprint": 1234567890123456789,
  "entriesLoaded": 3600000,
  "totalEntries": 12000000
}
```

`isComplete` ≡ `entriesLoaded >= totalEntries`. The cursor is a **count of entries emitted so
far** (not a phone number): resuming = "skip the first N of the canonical ascending stream",
which is pure run arithmetic (O(#runs), no iteration).

### 2.3 ⚠️ Prerequisite fix: deterministic plan fingerprint

`BlockingPlan.stateHash` currently uses Swift's `Hasher`, which is **randomly seeded per
process**. A hash computed in the app can never be compared with one computed in the extension —
the paged design (and the existing §2.4 intent) depends on exactly that comparison. Replace it
with a deterministic fingerprint:

```swift
/// Stable across processes and launches (FNV-1a over canonical run pairs).
public var fingerprint: UInt64
```

FNV-1a over each run's `base`/`count` in canonical (sorted, disjoint) order. Guarded by a
known-value test so the algorithm can never drift silently.

### 2.4 The decision function (pure, the heart of the design)

```swift
public enum PagedLoader {
    public enum Action: Equatable {
        case emitFirstPage                 // store is empty (non-incremental context)
        case restartAndEmitFirstPage       // removeAll + first page (state missing/stale)
        case emitPage(startIndex: Int64)   // continue from the cursor
        case alreadyComplete               // nothing to add
    }

    public static func nextAction(
        isIncremental: Bool,
        state: LoaderState?,
        planFingerprint: UInt64,
        totalEntries: Int64
    ) -> Action
}
```

| # | `isIncremental` | State | Fingerprint | Action | Scenario |
|---|---|---|---|---|---|
| 1 | `false` | any | any | `emitFirstPage` | First enable from Settings; iOS rebuilt the store. Store is empty — any persisted cursor is meaningless, start from 0. |
| 2 | `true` | `nil` | — | `restartAndEmitFirstPage` | State lost/invalidated → deterministic rebuild. |
| 3 | `true` | present | ≠ current | `restartAndEmitFirstPage` | Plan changed (user entry, Arcep update) → full rewrite. |
| 4 | `true` | present, incomplete | = current | `emitPage(startIndex: entriesLoaded)` | The normal driving loop. |
| 5 | `true` | present, complete | = current | `alreadyComplete` | Reload requested but nothing changed. |

`removeAllBlockingEntries()` is called **only** on `restartAndEmitFirstPage` (it requires an
incremental context; on a non-incremental context the store is already empty).

### 2.5 Page extraction (pure)

```swift
public extension BlockingPlan {
    /// The ascending numbers of one page: entries [startIndex, startIndex + maxCount)
    /// of the canonical stream. O(1) memory, O(#runs) positioning.
    func pageNumbers(startIndex: Int64, maxCount: Int64) -> BlockingPageSequence
}
```

Invariants (all property-tested):
- Concatenating `pageNumbers(k·P, P)` for k = 0… equals the full `numbers` stream exactly.
- Every page is strictly ascending and ≤ `maxCount` long.
- `startIndex ≥ totalEntries` yields an empty page; pages never straddle incorrectly across run
  boundaries (a page may end mid-run and the next resumes mid-run).

### 2.6 Extension algorithm (replaces the current single-pass `beginRequest`)

```swift
override func beginRequest(with context: CXCallDirectoryExtensionContext) {
    context.delegate = self
    let plan  = activePlan()                       // unchanged: SharedConfig ?? bundled
    let state = LoaderState.load()                 // App Group JSON
    let action = PagedLoader.nextAction(
        isIncremental: context.isIncremental,
        state: state,
        planFingerprint: plan.fingerprint,
        totalEntries: plan.totalEntries)

    var start: Int64 = 0
    switch action {
    case .emitFirstPage:              start = 0
    case .restartAndEmitFirstPage:    context.removeAllBlockingEntries(); start = 0
    case .emitPage(let s):            start = s
    case .alreadyComplete:
        context.completeRequest(); return
    }

    var emitted: Int64 = 0
    // Same streamed loop as today (autoreleasepool every 100k), but over
    // plan.pageNumbers(startIndex: start, maxCount: PagedLoader.pageSize).
    …

    try? LoaderState(planFingerprint: plan.fingerprint,
                     entriesLoaded: start + emitted,
                     totalEntries: plan.totalEntries).save()   // before completeRequest — see §2.8
    context.completeRequest()
}

func requestFailed(for _: CXCallDirectoryExtensionContext, withError error: Error) {
    LoaderState.invalidate()   // delete the file → next round takes row 2 (full restart)
}
```

### 2.7 App orchestration

`ExtensionBridge` gains a driving loop; `AppModel` exposes progress:

```swift
/// Drives reload rounds until the persisted state matches the current plan and is
/// complete. Bounded: ceil(total/pageSize) + 3 rounds, then surface an error state.
func syncExtension() async
```

- **Triggers:** (a) activation detected (`status == .enabled` after onboarding), (b) every
  config mutation (`persistAndReload` → `syncExtension`), (c) **every foreground transition**
  where status is enabled but persisted state is incomplete or stale — this makes the system
  self-healing: an interrupted load resumes the next time the user opens the app.
- Each `bridge.reload()` round: on success, re-read `LoaderState`, publish
  `entriesLoaded / totalEntries`; on error, invalidate the state file and retry once from
  scratch before giving up with a visible error.
- `isReloading` is replaced by a published `LoadProgress` (`idle / loading(Double) / complete /
  failed(String)`).
- A mutation that lands mid-loop is naturally correct: it changes the fingerprint, so the next
  round hits row 3 (`restartAndEmitFirstPage`) and the loop's bound is recomputed.

**UX (French copy, per design system):**

| State | Surface | Copy |
|---|---|---|
| Loading, round k | Activation screen + Dashboard hero | Determinate bar — « Chargement des numéros… 5 400 000 / 12 000 000 » (replaces §3.2's indeterminate spinner: paging finally gives us real progress for free) |
| Enabled but incomplete (user left mid-load) | Dashboard hero (new variant between "paused" and "active") | « Protection partielle — chargement en reprise… » + auto-resume |
| Failed after retries | Dashboard | « Le chargement a échoué. Réessayer » (button → invalidate + full resync) |
| Settings | Maintenance row | « Recharger la liste de blocage » → invalidate + full resync (recovery hatch for §2.8's residual risk) |

### 2.8 Failure model

| Failure | Behavior | Outcome |
|---|---|---|
| Killed mid-emission (jetsam, watchdog) | State not yet saved; iOS rolls back the partial request | Next round re-emits the same page. Idempotent. |
| `requestFailed` delegate fires | Extension invalidates state | Next round: full deterministic rebuild. |
| `reloadExtension` completion returns error (app side) | App invalidates state, retries once, else surfaces `failed` | User-visible retry path. |
| Hard kill between state save and `completeRequest` | State says page committed; store disagrees. **Not detectable** — CallKit has no entry-count/read API. | Residual risk. Window is milliseconds. Mitigations: Settings « Recharger la liste », automatic full resync on app update (version-stamped state), and any future plan change also heals it (row 3). |
| iOS spontaneously hands a non-incremental context (restore, migration, store purge) | Row 1: page 1 from scratch; state overwritten as incomplete | App's foreground trigger drives the remaining rounds. Self-healing. |
| User toggles extension off during load | Reload rounds fail while disabled; loop stops | Foreground trigger resumes after re-enable (non-incremental → row 1). |

Save-before-complete is deliberate: the alternative (app-side two-phase commit) breaks when
iOS itself invokes the extension with no app running, and adds a pending/committed protocol for
a milliseconds-wide window that Settings-recovery already covers.

### 2.9 What explicitly does NOT change

- `BlockingRun`, `BlockingRunMerger`, coalescing, validation, E.164 normalization.
- The strictly-ascending / O(1)-memory / autoreleasepool disciplines.
- `SharedConfig` ownership (app writes, extension reads) and the bundled-fallback behavior.
- No network, no new data collection — the privacy covenant is untouched.

## 3. Implementation plan

### Phase A — Core paging (unblocks device testing) ✅ exit: extension enables on device with full 12M coverage

- [x] `SilenciaKit`: replace `stateHash` with deterministic `fingerprint: UInt64` (FNV-1a) + known-value test; migrate the one caller.
- [x] `SilenciaKit`: `LoaderState` (Codable, App Group IO mirroring `SharedConfig`'s pattern, `invalidate()`).
- [x] `SilenciaKit`: `BlockingPlan.pageNumbers(startIndex:maxCount:)` + `PagedLoader.nextAction` + constants.
- [x] Tests: decision-matrix (all 5 rows), page-concatenation property test, page-boundary edge cases (mid-run resume, exact run edge, final partial page, empty page past end), `LoaderState` codec round-trip.
- [x] `Blocker`: rewrite `beginRequest` per §2.6 (keep chunked `autoreleasepool` loop); `requestFailed` → invalidate.
- [x] `App`: `AppModel.syncExtension()` driving loop with round bound + error handling; wired into activation, mutations, `start()`, and foreground.
- [x] **Background continuation (pulled forward from Phase C — product requirement: loading must not need the app in the foreground).** `syncExtension` holds a `UIBackgroundTask` assertion; `BackgroundSync` schedules a `BGProcessingTask` (`com.silencia.app.sync`) whenever the app backgrounds with an unfinished load; foreground resume stays the safety net. `UIBackgroundModes: processing` + permitted identifier in project.yml.
- [ ] Device validation: enable on iPhone 16 Pro → toggle sticks, `loader-state.json` shows 12,000,000/12,000,000; place a test call from a blocked-range number if possible.

### Phase B — UX & resilience

- [ ] Determinate progress UI on activation screen + dashboard partial-protection hero variant (French copy per §2.7); `LoadProgress` published state.
- [ ] Foreground auto-resume + « Réessayer » failure state.
- [ ] Settings « Recharger la liste de blocage » maintenance action.
- [ ] Version-stamped state → automatic full resync on app update.
- [ ] `DebugScreen` additions (`loading`, `partial`) so the simulator can render the new states.
- [ ] Device test matrix (extends implementation-plan §2.5): cold 7-round load on SE 2020 + iPhone 12 + latest; kill app mid-load → foreground resume; toggle off/on mid-load; add/remove custom entry mid-load; airplane mode (must be irrelevant).

### Phase C — Optimizations (post-validation, optional)

- [ ] User-entry delta fast path: when only `userEntries` changed and the Arcep set is loaded, emit `removeBlockingEntry`/`addBlockingEntry` deltas (≤ 500k by §3.3 caps) instead of a full rewrite — restores today's "near-instant add". Requires persisting the applied user runs in `LoaderState`; diff computation is pure and tested.
- [x] ~~`BGProcessingTask` continuation~~ — pulled forward into Phase A (product requirement).
- [ ] Measure first-load duration on the floor device via MetricKit (on-device only).

## 4. Consequences for existing docs

- `implementation-plan.md` §2.3's single-pass code sample and §2.4's full-vs-incremental model
  are superseded by this document (pointer added there).
- `CLAUDE.md`'s extension rule gains the per-request cap as a hard constraint alongside the
  memory budget.
- Phase 0's go/no-go gate ("stable full load under memory limit on floor device") is amended:
  memory was never the blocker; the gate is now "full paged load completes and the toggle
  sticks on the floor device".
