# Silencia — iOS Implementation Plan

**Version:** 0.1 (Draft)
**Date:** July 2026
**Companion doc:** `product-spec.md`

---

## 1. Architecture overview

```
┌─────────────────────────────────────────────────────┐
│ Silencia.app (SwiftUI)                              │
│  ├─ Onboarding & activation flow                    │
│  ├─ Dashboard (protection status)                   │
│  ├─ Custom block list management                    │
│  └─ RangeStore (Arcep ranges + user entries)        │
│           │ App Group (shared container)            │
│           ▼                                         │
│ SilenciaBlocker.appex (Call Directory Extension)    │
│  └─ Streams blocking entries to CallKit             │
│                                                     │
│ [v1.x] SilenciaSMS.appex (Message Filter Extension) │
└─────────────────────────────────────────────────────┘
        │ (read-only, no personal data)
        ▼
 Static CDN: ranges.json (signed) — Arcep prefix defs
```

**Stack decisions**

| Concern | Choice | Rationale |
|---|---|---|
| Language/UI | Swift 6 / SwiftUI | Solo-friendly, modern, iOS 16+ target |
| Min iOS version | iOS 16 | Covers ~95% of FR devices in 2026; keeps CallKit APIs modern |
| Persistence | JSON files in App Group container | Tiny data; no Core Data/SwiftData overhead needed |
| Purchase model | Paid upfront — **no IAP, no StoreKit** | Buying the app is the lifetime deal (business-plan.md §1) |
| Backend | **None** (static JSON on CDN, e.g. Cloudflare Pages/R2) | Zero server cost, zero personal data |
| Analytics | App Store Connect only | Privacy covenant |
| CI | Xcode Cloud (free tier) | Simplest for solo dev |

## 2. The core: Call Directory Extension

### 2.1 How blocking works

- The extension implements `CXCallDirectoryProvider.beginRequest(with:)`.
- iOS calls it when the user enables the extension or when the app requests `CXCallDirectoryManager.reloadExtension(withIdentifier:)`.
- Entries are written via `context.addBlockingEntry(withNextSequentialPhoneNumber:)` — **strictly ascending order required**, E.164 format as `Int64` (e.g., `+33162000000` → `33162000000`).
- iOS persists entries into a system database; blocked calls never ring and appear in Recents as blocked.

### 2.2 The Arcep ranges as data

```json
// ranges.json (bundled + remote-refreshable, signed)
{
  "version": 3,
  "updated": "2026-07-01",
  "ranges": [
    { "prefix": "33162", "label": "01 62" },
    { "prefix": "33163", "label": "01 63" },
    { "prefix": "33270", "label": "02 70" },
    { "prefix": "33271", "label": "02 71" },
    { "prefix": "33377", "label": "03 77" },
    { "prefix": "33378", "label": "03 78" },
    { "prefix": "33424", "label": "04 24" },
    { "prefix": "33425", "label": "04 25" },
    { "prefix": "33568", "label": "05 68" },
    { "prefix": "33569", "label": "05 69" },
    { "prefix": "33948", "label": "09 48" },
    { "prefix": "33949", "label": "09 49" }
  ]
}
```

Each prefix covers 10⁶ numbers → **12,000,000 blocking entries total**.

### 2.3 Memory strategy (the critical constraint)

> **⚠️ Superseded in part by `paged-loading-plan.md`.** Device testing (2026-07-06) proved a
> second hard constraint this section missed: CallKit caps each `beginRequest` at
> **2,000,000 entries** (error Code=5). The single-pass loop sketched below is therefore
> invalid for the 12M set — entries must be loaded in ≤1.8M pages across multiple
> app-driven reload rounds. The memory rules below still stand.

The extension runs under a hard memory limit (~12 MB, undocumented; treat 6 MB as the working budget). Rules:

1. **Never materialize the number list.** Generate sequentially:

```swift
for range in ranges.sorted(by: { $0.base < $1.base }) {
    let base = range.base            // e.g. 33_948_000_000
    for offset in 0..<1_000_000 {
        context.addBlockingEntry(withNextSequentialPhoneNumber: base + Int64(offset))
    }
}
```

   Constant memory. No arrays, no Set dedup (ranges are disjoint by construction; enforce disjointness at data-validation time in the main app, not in the extension).

2. **Merge user entries into the same ascending stream.** Custom numbers/prefixes must be interleaved in sorted order with the Arcep stream (two-pointer merge between the sorted user list and the range generator). User list is small (≤ a few hundred); load it from the App Group JSON.

3. **Autorelease hygiene.** Wrap chunks (e.g., every 100k entries) in `autoreleasepool` — CallKit bridging can accumulate transient objects.

4. **Handle `isInterrupted`.** If iOS kills a long request, the extension is re-invoked; the design must be idempotent (full reload path recomputes everything deterministically).

### 2.4 Incremental updates

> **Superseded by `paged-loading-plan.md`** — the first load is itself a sequence of
> incremental paged requests (7 rounds of ≤1.8M), driven by the app, with a cursor persisted
> in the App Group (`loader-state.json`). Plan changes trigger a full paged rewrite keyed on a
> deterministic plan fingerprint; the user-entry delta fast path is its Phase C.

### 2.5 Load-time expectations & testing matrix

- Benchmark on the oldest supported device (target: iPhone 8/SE 2-class if iOS 16 floor → in practice iPhone SE 2020 is the floor device).
- Expected first full load: tens of seconds to ~2 minutes on old hardware. Acceptable; happens in background after activation.
- **Test matrix (must pass before submission):**
  - iPhone SE 2020 (worst case RAM/CPU)
  - iPhone 12 (mainstream installed base)
  - Latest iPhone
  - Each: cold full load, incremental add, incremental remove, interrupted load (force reload mid-write), extension disabled → re-enabled.

### 2.6 No tier gating

The app is paid upfront (business-plan.md supersedes the freemium model of spec v0.1): every
install streams **all** ranges plus the user's entries. There is no entitlement state anywhere —
the App Group config carries only range data and custom entries.

## 3. Main app

### 3.1 Modules

```
Silencia/
├─ App/                    // entry, DI, routing
├─ Features/
│  ├─ Onboarding/          // promise → explainer → activation → success
│  ├─ Dashboard/           // status hero, ranges list, update date
│  ├─ BlockList/           // custom numbers & prefixes CRUD
│  └─ Settings/            // privacy policy, FAQ, support
├─ Core/
│  ├─ RangeStore/          // ranges.json load/validate/refresh, App Group IO
│  ├─ ExtensionBridge/     // CXCallDirectoryManager status + reload orchestration
│  └─ DesignSystem/        // colors, type, components
└─ SilenciaBlocker/        // the extension target
```

### 3.2 Activation flow (F2) — engineering details

- Status check: `CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier:)` on every `scenePhase == .active` transition.
- Deep link: `App-prefs:` schemes are unreliable/rejected territory. Use the supported path: open Settings root via `UIApplication.openSettingsURLString` and rely on illustrated steps. Test what iOS 18/19 allows at build time; do not ship private URL schemes.
- On detection of `.enabled`: trigger `reloadExtension`, show progress UI (indeterminate + staged copy: « Chargement des 12 millions de numéros… »), then success state.
- Progress reporting: the extension cannot easily report progress to the app. Options: (a) indeterminate spinner with staged copy (ship this), (b) extension writes a progress file to the App Group every N entries and the app polls it (nice-to-have; measure the IO cost first).

### 3.3 Custom block list (F3)

- Input validation: normalize to E.164 (+33 …), reject non-FR unless full E.164 provided, dedupe against Arcep ranges ("déjà couvert ✅" feedback).
- Custom prefixes: minimum length 6 digits after +33 (i.e., max 10,000 numbers per custom prefix) to bound entry counts; hard cap total custom-generated entries (e.g., 500k) with clear UI feedback.
- Every mutation → save to App Group → `reloadExtension` (incremental path).

### 3.4 Ranges refresh (remote config)

- On app foreground (throttled to 1×/week): fetch `ranges.json` from CDN, verify Ed25519 signature against a public key pinned in the app, compare `version`, apply → incremental extension reload + optional local notification (opt-in) « Mise à jour Arcep appliquée ».
- Failure mode: silent; bundled ranges always work. The app never *requires* network.

### 3.5 Purchases

None in-app. The app is paid upfront on the App Store; Apple handles payment, refunds, and
re-downloads. Enable **Family Sharing for the app itself** in App Store Connect — supports the
"gift to parents" use case at the cost of some revenue; strategically correct.

## 4. SMS filtering (v1.x, scoped now)

- `ILMessageFilterExtension` classifying incoming SMS from unknown senders; if sender number matches Arcep ranges → `.junk`, subcategory `.promotion`.
- Constraint: message filters only see messages from senders **not in contacts** — fine for this use case.
- Simple prefix match, no ML, no network (deferral to a server is possible in the API but violates our privacy covenant — never use it).
- Separate onboarding step (Settings → Messages → Unknown & Spam).

## 5. Privacy & App Review

- **Privacy Nutrition Label:** "Data Not Collected." Make it literally true: no third-party SDKs at all (no Firebase, no Sentry — use MetricKit + on-device logs exported by user action for support).
- App Review notes: cite the Arcep decision (2022) defining prospecting number ranges; explain deterministic blocking; reference precedent apps. Include a demo video of activation flow (reviewers often lack a second phone to test calls).
- Prepare for the classic rejection risk: "app requires user to leave the app to function" — the onboarding must make in-app value visible (dashboard, block list) beyond the Settings toggle.

## 6. Delivery plan

Solo developer, part-time (~10–15 h/week assumed). Sequenced for de-risking: the extension is the only hard part, so it comes first.

### Phase 0 — Spike (week 1)
- [ ] Bare-bones extension writing all 12M entries on device; measure memory & duration on iPhone SE 2020.
- [ ] Validate incremental add/remove.
- [ ] **Go/no-go gate:** stable full load under memory limit on floor device.

### Phase 1 — Core product (weeks 2–5)
- [ ] RangeStore + App Group plumbing, ranges.json schema + validation.
- [ ] ExtensionBridge (status detection, reload orchestration, staged progress UI).
- [ ] Onboarding flow (4 screens) + success state.
- [ ] Dashboard v1.
- [ ] Custom block list CRUD with incremental reloads.

### Phase 2 — Monetization & polish (weeks 6–8)
- [ ] Design system pass, French copywriting, accessibility (VoiceOver on onboarding — senior audience), Dynamic Type.
- [ ] Settings, FAQ (incl. "pourquoi ça marche" and collateral-blocking note), privacy policy.
- [ ] Remote ranges refresh + signature verification.

### Phase 3 — Hardening & launch (weeks 9–11)
- [ ] Full device test matrix (§2.5), interrupted-load chaos testing.
- [ ] TestFlight beta: 20–50 French users (recruit via personal network + r/vosfinances-adjacent communities); measure activation rate.
- [ ] App Store assets: screenshots, preview video of activation, keyword set.
- [ ] Submission with review notes + demo video.

### Phase 4 — Post-launch (weeks 12+)
- [ ] Monitor activation rate & reviews; iterate on the activation screen (this is where conversion lives or dies).
- [ ] Ship SMS filtering (v1.1).
- [ ] Widget (v1.2).
- [ ] Begin Android scoping (`CallScreeningService` — separate plan).

## 7. Open questions

1. **Name availability:** reserve "Silencia" in App Store Connect immediately; INPI/EUIPO search before spending on brand assets. Fallbacks: Raccroche, Tranquille.
2. **Price:** 5,99 € at launch per `business-plan.md` §2.2; revisit at +6 months. Raising is safe; lowering annoys early buyers.
3. **Progress reporting** during first load: ship indeterminate, measure complaints, add App Group progress file only if needed.
4. **iOS 26 CallKit changes:** verify at Xcode beta time whether Call Directory APIs or Settings paths changed; the activation screenshots must match the current iOS Settings layout at launch.
