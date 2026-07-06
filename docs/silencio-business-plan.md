# Silencio — Business Plan

**Version:** 0.1 (Draft)
**Date:** July 2026
**Model:** Paid-upfront iOS app, French market
**Companion docs:** `silencio-product-spec.md`, `silencio-implementation-plan.md`

> ⚠️ This version supersedes the freemium model in the product spec v0.1. Business model is now **paid upfront** (buy the app once on the App Store, own it forever). The spec's paywall/free-tier sections (F5, §6.1, §7.2) must be updated accordingly — this simplifies the build (no StoreKit paywall, no gating logic).

---

## 1. Executive summary

Silencio is a one-time-purchase iOS app that deterministically blocks French telemarketing calls using the Arcep-mandated prospecting number ranges. Zero configuration, zero data collection, zero recurring cost.

**The single most important strategic fact:** on **August 11, 2026 — five weeks from now — the law of June 30, 2025 (loi n° 2025-594) makes all unsolicited telemarketing illegal without prior opt-in consent, and Bloctel shuts down permanently.** This event is simultaneously:

- **The biggest marketing opportunity this product will ever have.** Massive national press coverage is guaranteed; millions of Bloctel registrants become "orphaned" and will search for alternatives; the keyword "bloctel" becomes a free acquisition channel pointing at a dead service.
- **The core thesis risk.** "Telemarketing is now banned anyway — why pay for a blocker?" The counter-narrative (and it is true) is: consent-based and fraudulent calls continue, enforcement is weak, and the legal callers *still must use the Arcep ranges* — Silencio blocks both the compliant and the annoying-but-consented.

**Recommendation: compress the delivery plan to ship before August 11, 2026, even as a v0.9.** Launch timing dominates every other variable in this plan, including marketing budget.

## 2. Business model

| Parameter | Value |
|---|---|
| Model | Paid upfront (App Store purchase) |
| Recommended price | **5,99 €** (see §2.2) |
| Apple commission | 15% (Small Business Program, < $1M/yr) |
| VAT (France) | 20%, deducted before commission |
| **Net proceeds per sale** | **≈ 4,24 €** (5,99 / 1,20 × 0,85) |
| Marginal cost per user | ≈ 0 € (static CDN file, email support) |
| Recurring costs | Apple Developer Program 99 $/yr, CDN ~0 €, domain ~15 €/yr |

Every euro of revenue above ~150 €/year is margin. The model's weakness is the flip side: **no recurring revenue, no compounding LTV** — growth must come from continuous new-buyer acquisition, and paid advertising must recover its cost in a single 4,24 € transaction.

### 2.1 Reference pricing (competitive context)

Begone, the direct competitor, is freemium: free app with manual range configuration, premium at 1,99 €/month, 19,99 €/year, or 79,99 € lifetime. Silencio at 5,99 € one-time is dramatically cheaper than any Begone paid tier while offering a better out-of-box experience. This is a deliberate wedge: "moins cher que 3 mois de Begone Premium, à vie, sans rien configurer."

### 2.2 Price sensitivity

| Price | Net/sale | Notes |
|---|---|---|
| 3,99 € | 2,83 € | Impulse zone; hard to fund any paid acquisition |
| **5,99 €** | **4,24 €** | Recommended: still impulse-priced, credible vs Begone, leaves thin ASA margin |
| 7,99 € | 5,66 € | Defensible on value; test after launch reviews stabilize ≥ 4,7★ |
| 9,99 € | 7,08 € | Psychological ceiling for a FR utility app paid upfront |

Paid-upfront conversion is brutally sensitive to rating and review count in the first weeks. Launch at 5,99 €; revisit at +6 months. Raising is safe; lowering annoys early buyers.

## 3. Market sizing (France, iOS only)

| Layer | Estimate | Basis |
|---|---|---|
| French smartphone users | ~55 M | Adult population × penetration |
| iPhone installed base (TAM devices) | ~20–24 M | iOS ≈ 35–40% share in France |
| Adults actively annoyed by telemarketing | 97% say it irritates them | UFC-Que Choisir survey, Oct 2024 |
| **SAM** — iPhone owners willing to *act* (install a blocker) | ~2–4 M | Bloctel had millions of registrants; a fraction are iOS + proactive |
| **SOM** — realistically reachable buyers over 3 years | **50k–200k** | Paid-app friction cuts hard; category leader precedent |

The honest framing: this is a **niche utility with a real but capped ceiling**. Begone's multi-year presence, strong ratings, and press coverage demonstrate the demand exists; the paid-upfront barrier means Silencio converts a thinner slice of it than a free app would.

## 4. Revenue scenarios

All figures are **net proceeds** (after VAT + Apple 15%), at 5,99 € → 4,24 €/sale. Three scenarios per horizon; "with marketing" assumes the budgets in §5.

### 4.1 Short term — launch to month 6

The trajectory is dominated by one binary: **do you catch the August 11 press wave or not.**

**Without marketing (organic only: ASO + word of mouth):**

| Scenario | Sales/month (avg) | Net revenue/month | Cumulative 6 mo |
|---|---|---|---|
| Pessimistic (missed the wave, buried in search) | 50 | 210 € | ~1 300 € |
| Base (ranked on "démarchage"/"bloctel" keywords) | 250 | 1 060 € | ~6 400 € |
| Optimistic (1–2 press pickups organically) | 800 | 3 390 € | ~20 000 € |

**With marketing (PR push + ASA, ~1 500 €/month, §5):**

| Scenario | Sales/month (avg) | Net revenue/month | Net after marketing | Cumulative 6 mo (net of spend) |
|---|---|---|---|---|
| Pessimistic | 300 | 1 270 € | −230 € | ~−1 400 € |
| Base | 900 | 3 820 € | 2 320 € | ~14 000 € |
| Optimistic (press wave + featuring) | 3 000 | 12 700 € | 11 200 € | ~67 000 € |

The optimistic case is not fantasy: a French-made, privacy-clean, one-price app launching the week Bloctel dies is a ready-made story for BFM/Le Parisien/Presse-citron/Frandroid/BDM — the same outlets that already covered Begone repeatedly. One national TV or radio mention historically moves thousands of installs in this category.

### 4.2 Medium term — months 6–24

Post-launch decay is the default for paid utilities: sales settle at a baseline driven by App Store search. Levers: ratings velocity, Android launch (doubles TAM; French Android share ~60–65%), seasonal press (each new DGCCRF enforcement story re-activates the topic).

| Scenario | iOS baseline sales/mo | + Android (from mo ~12) | Net revenue/mo (combined) |
|---|---|---|---|
| Pessimistic | 80 | +60 | ~600 € |
| Base | 300 | +250 | ~2 300 € |
| Optimistic | 700 | +700 | ~5 900 € |

Marketing in this phase: maintain ASA at 500–800 €/month only if blended CPA stays under ~3 €; otherwise cut to zero and rely on organic — the paid-upfront model tolerates almost no acquisition cost.

### 4.3 Long term — years 2–5

Two structural forces, one negative and one positive:

- **Negative:** if the opt-in law is well enforced, call volume genuinely drops, the pain fades, and the category shrinks. Expect secular decline in searches.
- **Positive:** fraud and illegal prospecting will not disappear (CPF/rénovation scams ignored the previous bans too); Apple may never ship native range-blocking; and a shrinking market also starves competitors.

| Scenario | Cumulative net revenue by end of year 5 (iOS+Android) |
|---|---|
| Pessimistic | 30 000 – 50 000 € |
| Base | 100 000 – 180 000 € |
| Optimistic | 300 000 – 500 000 € |

**Read this table honestly:** Silencio is a profitable side product — excellent €/hour for a solo developer with your profile, near-zero running costs, and a compounding brand asset (privacy-first French utility). It is not a venture-scale business, and its ceiling is set by regulation you don't control. It should never compete for Rempart AI's calendar time; its budget is weekends.

## 5. Marketing plan & budgets

Ranked by expected ROI. The paid-upfront economics (4,24 € to recover per sale) disqualify most paid channels; the plan is PR-led.

### 5.1 Tier 1 — PR around August 11 (budget: 0–500 €, effort: high)

The centerpiece. Deliverables to prepare **before** launch:

- **Press kit** (FR): the story is "Bloctel meurt le 11 août — voici l'application française qui bloque définitivement le démarchage, sans abonnement, sans données." Include the Arcep-ranges explainer, screenshots, founder angle (French engineer, ex-Microsoft, privacy-first).
- **Target list:** the exact outlets that covered Begone — Blog du Modérateur, Clubic, Presse-citron, Frandroid/iGeneration, 01net, Le Parisien conso, UFC-Que Choisir (editorial), BFM Tech&Co, France Info conso segments.
- **Timing:** pitch the week of August 4; journalists will be writing their "fin de Bloctel, que faire ?" pieces then.
- **Optional spend:** 300–500 € for a freelance press-relations contractor with existing conso-tech contacts, if your own outreach stalls.

Expected impact: this single wave, if caught, outperforms every euro of paid acquisition in this plan.

### 5.2 Tier 2 — ASO + the "bloctel" keyword (budget: 0 €, effort: medium, ongoing)

- Title/subtitle/keywords as per product spec, **plus aggressive targeting of "bloctel", "bloctel gratuit", "remplacer bloctel", "alternative bloctel"** — a large, motivated search audience about to lose its destination. This is a once-in-a-category keyword arbitrage.
- Ratings engine: SKStoreReviewController prompt after the success state ("12 millions de numéros bloqués ✅") — the emotional peak. Rating velocity in weeks 1–4 determines organic ranking for years.

### 5.3 Tier 3 — Apple Search Ads (budget: 500–1 500 €/month, kill-switch discipline)

- Start with Search Match off; exact-match on: démarchage, bloquer démarchage, spam téléphone, bloctel, begone (competitor conquesting is legal and effective).
- French utility CPTs typically run 0,50–1,50 €. With tap-to-paid-purchase conversion for a 5,99 € app realistically at 3–8%, CPA lands at 10–30 € — **unprofitable** — except on high-intent exact terms ("bloquer démarchage", "bloctel") where conversion can reach 15–25% and CPA falls toward 2–4 €.
- Rule: run 2-week cohorts; kill any keyword with CPA > 3,50 €. Expected steady state: a small profitable core spending 300–800 €/month, not a growth engine.

### 5.4 Tier 4 — Creators (budget: 0–2 000 € one-off, opportunistic)

- French tech YouTube/TikTok (consumer-protection and iPhone-tips creators). One integrated mention in a "fin du démarchage" explainer video around August 11.
- Prefer revenue-share/promo-code-free gifting first; pay flat fees only for creators with proven FR conso audiences (CPM-equivalent < 20 €).

### 5.5 Not worth it (for a 5,99 € paid app)

- Meta/TikTok performance ads: CPI for FR iOS utility 1,50–4 € *per install of a free app*; for paid-upfront, effective CPAs are far beyond 4,24 €. Skip.
- Google Ads, influencer subscriptions, app-review sites with paid placements: same math, worse tracking (ATT).

### 5.6 Budget summary

| Phase | Period | Budget | Composition |
|---|---|---|---|
| Launch sprint | Jul–Sep 2026 | **1 000 – 3 000 € total** | Press kit assets 0–500 €, PR freelance 0–500 €, ASA 500–1 500 €/mo × 2, creator 0–500 € |
| Steady state | Oct 2026 → | **0 – 800 €/mo** | ASA profitable core only |
| Android launch | ~mid-2027 | 1 000 – 2 000 € one-off | Repeat the playbook, Play Store ASO |

Total year-1 marketing: **3 000 – 10 000 €** depending on ASA performance. The plan is deliberately PR-heavy and cash-light because unit economics forbid anything else.

## 6. P&L sketch — base scenario, year 1

| Line | Amount |
|---|---|
| Net proceeds (≈ 5 500 sales × 4,24 €) | +23 300 € |
| Marketing | −5 000 € |
| Apple Developer + domain + CDN + misc | −250 € |
| Accounting/legal (micro-entreprise regime) | −500 € |
| **Pre-tax profit** | **≈ +17 500 €** |

Fiscal note (flagging, not advising): app revenue would flow through whichever structure you choose — micro-entreprise BNC/BIC, or as a product line under a company. Given your PSE/ARE optimization and the planned Lupus Capital holding, where to house Silencio (personal micro vs. SASU subsidiary) has real consequences for ARE maintenance and social charges — worth a session with your expert-comptable before the first euro lands, not after.

## 7. Risks specific to this business plan

| Risk | Impact | Mitigation |
|---|---|---|
| **Miss the Aug 11 window** | Loses the single biggest free-acquisition event; base case drops toward pessimistic | Cut scope ruthlessly: MVP = 12 ranges + activation flow + custom list. Everything else post-launch |
| **"Le démarchage est interdit, pourquoi payer ?"** | Softens demand from late 2026 | Messaging pivot ready at launch: "La loi interdit. Silencio fait respecter." Illegal/consented calls persist; ranges remain in force for compliant callers |
| Enforcement actually works, calls collapse | Long-term demand decay | Accept: harvest, don't invest; Android extends runway |
| Begone (or Apple) ships one-tap Arcep blocking | Erodes differentiation | Speed + brand + price clarity; no durable moat exists here — plan assumes it |
| Paid-upfront conversion below assumptions | All scenarios shift down one row | Price drop to 3,99 € as circuit-breaker; or pivot to freemium (keep the code path simple enough to allow it) |
| App Review delays past Aug 11 | Missed window | Submit 3 weeks early; expedited-review request citing the regulatory date if stuck |

## 8. Decision summary

1. **Ship before August 11, 2026.** This beats every marketing euro. If the current 11-week plan doesn't fit, cut Phase 2 polish and ship the core.
2. Price at **5,99 €**, Small Business Program enrolled, Family Sharing on.
3. Marketing = **PR-first, ~1–3 k€ launch budget**, ASA only under strict CPA discipline, no social performance ads.
4. Treat the P&L as a **capped, high-margin side product** (~15–25 k€ pre-tax in year 1 base case; 100–180 k€ cumulative over 5 years). Protect Rempart AI's time above all.
5. Decide the fiscal housing (micro vs. holding subsidiary) with your expert-comptable **before launch**.
