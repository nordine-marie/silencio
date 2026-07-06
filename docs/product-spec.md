# Silencia — Product Specification

**Version:** 0.1 (Draft)
**Date:** July 2026
**Owner:** Nordine
**Status:** Pre-development

---

## 1. Vision

**Silencia is the "install and forget" telemarketing blocker for France.**

One-time purchase. Zero configuration. You install it, flip one switch, and every French telemarketing call is silenced forever — because in France, telemarketers are *legally required* to call from known number ranges (Arcep decision, effective January 1, 2023). Silencia exploits this regulatory quirk to deliver deterministic blocking, not heuristic guessing.

**Tagline (FR):** « Installez. Activez. Tranquille à vie. »
**Tagline (EN, internal):** "Install it once. Silence forever."

## 2. Problem

- French consumers receive on average 4–6 telemarketing calls per week despite Bloctel (the state opt-out list, widely considered ineffective).
- Existing solutions (Begone, Orange Téléphone) work but require configuration: choosing which prefixes to block, understanding what Arcep ranges are, managing subscriptions or ads.
- The market leader on this exact mechanic (Begone) is a paid app with a utilitarian UX aimed at people who already understand the problem. There is room for a mainstream, benefit-first product.

## 3. Positioning

| | **Silencia** | Begone | Orange Téléphone |
|---|---|---|---|
| Setup | Zero-config, all Arcep ranges pre-enabled | User selects ranges | Account-lite, ads/data model |
| Business model | **One-time lifetime purchase** | Paid app | Free (Orange-funded) |
| Target user | Mainstream French public (incl. seniors) | Tech-aware users | Orange ecosystem |
| Custom blocking | Yes (additional numbers/prefixes) | Yes | Limited |
| Data collection | **None. No account. No server.** | Minimal | Orange data policies |

**Core differentiators:**
1. **OOB (out-of-box) coverage** — no decisions to make. Blocking is ON for all Arcep telemarketing ranges the moment the extension is enabled.
2. **Lifetime deal** — pay once, own it forever. Direct counter-positioning against subscription fatigue.
3. **Privacy absolutism** — no account, no analytics SDK, no server calls with personal data. All blocking happens on-device. This is a marketable feature in France (CNIL-aware public).
4. **French-first** — French App Store copy, French onboarding, French support. English is secondary.

## 4. Target audience

- **Primary:** French adults 35–70, non-technical, exasperated by démarchage. Includes seniors buying (or receiving as a gift from their children) a "peace of mind" product.
- **Secondary:** Tech-aware users comparing against Begone who prefer lifetime pricing and cleaner UX.
- **Gift use case:** "Offrez la tranquillité à vos parents" is an explicit marketing angle. The zero-config promise makes it giftable.

## 5. Product principles

1. **Zero decisions by default.** Every mandatory choice in onboarding is a failure.
2. **The only hard step is Apple's fault — own it.** iOS requires the user to manually enable the extension in Settings. This is the single point of friction; the entire onboarding is engineered around making that one step foolproof.
3. **Show, don't configure.** The main screen shows what's being blocked (counter of blocked ranges, blocked-call stats where available), not settings.
4. **Lifetime means lifetime.** Arcep range updates ship as free app updates. No "Silencia 2" upsell for the core promise.

## 6. Feature set

### 6.1 MVP (v1.0)

**F1 — Pre-loaded Arcep blocking (the core)**
- All 12 Arcep telemarketing prefixes blocked out of the box:
  - 01 62, 01 63, 02 70, 02 71, 03 77, 03 78, 04 24, 04 25, 05 68, 05 69, 09 48, 09 49
- Implemented via CallKit Call Directory extension (deterministic blocking at the system level — calls never ring).
- Ranges stored as data (remote-configurable via signed static JSON on CDN) so future Arcep changes don't require an App Store review cycle to *define*, only to *ship* (the extension reload happens locally).

**F2 — Guided extension activation**
- Step-by-step onboarding with annotated screenshots/animation for: Settings → Apps → Phone → Call Blocking & Identification → enable Silencia.
- Live status detection: app polls `CXCallDirectoryManager.getEnabledStatus` and celebrates ("✅ Vous êtes protégé") the moment the user returns with the extension enabled.
- If disabled, the home screen shows a persistent, friendly call-to-action — never a silent failure.

**F3 — Personal block list**
- Add individual numbers manually or from recent-call paste.
- Add custom prefixes (e.g., block an entire range like `0162` is already covered; user might add a specific spam prefix they encounter).
- Cap custom prefixes to sane sizes to protect extension memory budget (see implementation plan).

**F4 — Blocking dashboard**
- "Protection active" hero state with count of ranges covered (~12 million numbers).
- Last data update date.
- Simple French copy explaining *why* this works (Arcep regulation) — builds trust in the deterministic claim.

**F5 — Lifetime purchase**
- Distribution model: **free download + one-time non-consumable IAP** («Silencia à vie»).
- Free tier: blocks 2 of the 12 ranges (enough to prove it works) + 5 custom numbers.
- Lifetime unlock: all ranges + unlimited custom entries. Target price: **9,99 €** (launch: 6,99 € promo).
- Rationale for freemium-over-paid-upfront: paid-upfront apps convert terribly cold; the free tier lets word-of-mouth and press drive installs, and the demonstrated blocking creates the upgrade moment.

### 6.2 v1.x (fast follows)

- **SMS spam filtering** (ILMessageFilterExtension): filter SMS from the same Arcep ranges into the Junk folder. High perceived value; low effort once ranges infra exists.
- **Widget:** protection status on the home screen.
- **Blocked-range changelog:** in-app note when Arcep ranges change ("Mise à jour Arcep du …").

### 6.3 Explicitly out of scope (v1)

- Caller ID / reverse lookup (requires server infrastructure and data licensing; breaks the privacy story).
- Crowdsourced spam lists (moderation burden, false positives, breaks determinism claim).
- Android (planned later; different tech — `CallScreeningService` — and a separate spec).
- Accounts, sync, backend of any kind beyond the static ranges JSON.

## 7. UX flows

### 7.1 First launch (target: < 90 seconds to protected)

1. **Splash → Promise screen:** one sentence + one button. « Bloquez tout le démarchage téléphonique. À vie. » → [Commencer]
2. **How it works (1 screen, skippable):** the Arcep explanation in 2 sentences. Builds trust, not required reading.
3. **Activation screen:** THE screen. Big button « Ouvrir les Réglages » (deep link as far as iOS allows), followed by illustrated steps. App detects activation on return.
4. **Success state:** « ✅ 12 millions de numéros bloqués. Vous n'entendrez plus jamais un démarcheur. »
5. Free tier active; upgrade prompt is present but not blocking.

### 7.2 Upgrade flow

- Trigger points: attempting to enable a locked range, adding a 6th custom number, or the settings "Passer à vie" row.
- Single screen: price, « une fois, pour toujours », restore purchases link, no dark patterns, no countdown timers. The anti-subscription positioning must be credible.

### 7.3 Steady state

- App is expected to be opened rarely. The product succeeds when the user forgets it exists. Push notifications: **none** except (optional, opt-in) "Arcep ranges updated" informational notices.

## 8. Business model

- **One-time IAP: 9,99 €** (non-consumable). Launch promo 6,99 €.
- No subscription, no ads, no data monetization — ever. This is a brand covenant, stated verbatim on the App Store page.
- Unit economics: no server costs beyond a static CDN file (~negligible). Support via email. Sustainable at low volume; the lifetime model works *because* marginal cost per user ≈ 0.
- Revenue expectations (order of magnitude): Begone's category proves French willingness to pay for this. 1,000 sales/month at 9,99 € ≈ 7 k€/month net of Apple's 15% (Small Business Program). This is a side-product, not a venture.

## 9. Naming, brand, App Store

- **Name:** Silencia.
- **App Store title:** « Silencia : Anti-Démarchage » (brand + keyword).
- **Subtitle:** « Bloqueur d'appels commerciaux » .
- **Keywords:** démarchage, bloquer, appels, spam, téléphone, arcep, bloctel, indésirable.
- **Locale:** fr-FR primary; en-US secondary (minimal).
- Screenshots: benefit-first («Installez. Activez. Tranquille.»), one screenshot dedicated to the privacy promise, one comparing "before/after" call log.

## 10. Legal & compliance notes

- Blocking Arcep-designated ranges is lawful: these prefixes are *allocated* to commercial prospecting platforms by regulation; blocking them cannot suppress legitimate personal calls by design.
- **Edge case to document in FAQ:** legitimate non-telemarketing services could theoretically use these ranges in violation of the numbering plan — collateral blocking is acceptable and the responsibility lies with the caller's numbering compliance.
- Privacy: no personal data processed off-device → minimal GDPR surface. Privacy policy still required (App Store) — state that custom block lists never leave the device.
- Trademark: run INPI/EUIPO search on "Silencia" in relevant Nice classes (9, 38, 42) before launch. Known conflict risk: "Silencia" is a common word; check app-name availability on App Store Connect early (name reservation).

## 11. Success metrics

| Metric | Target (6 months post-launch) |
|---|---|
| Activation rate (extension enabled / installs) | > 70% |
| Free → lifetime conversion | > 8% |
| App Store rating (FR) | ≥ 4.7 |
| Refund rate | < 2% |
| Support tickets per 1,000 users | < 5 |

Activation rate is the metric that matters most: it measures the OOB promise. Instrumentation must be privacy-preserving (on-device or aggregate-only via StoreKit/App Store Connect analytics — no third-party SDK).

## 12. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Arcep changes/extends ranges | Medium | Ranges as remote data; free updates; changelog feature |
| Regulation makes ranges obsolete (e.g., outright ban on cold calling) | Low/Medium | The proposed 2026+ opt-in consent law would *reduce* démarchage; Silencia pivots messaging to "blocks the outlaws" — offenders won't respect consent either |
| Apple rejects mass-blocking extension | Low | Begone precedent exists; ranges are regulator-defined, defensible in review notes |
| Extension memory crash on older devices | Medium | Streaming writes, chunked incremental loads, hard testing on oldest supported hardware (see implementation plan) |
| Begone copies OOB positioning | Medium | Compete on brand, lifetime pricing clarity, and polish; the moat is thin — speed matters |
