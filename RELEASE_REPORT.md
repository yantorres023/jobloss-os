# RELEASE REPORT — JobLoss OS

Date: 2026-09-25 · Branch: `claude/jobloss-os-5e4ecw` · Mode: autonomous one-shot run

## 1. Verdict: **GO (narrow, conditional)** for a closed beta. **Not ready for a public store release.**

GO for a free, local-first, **Texas-only** organizer: official-sourced, versioned, conservative about dates, and built so the
date on the user's letter always wins. Paid B2C was rejected. Public release is blocked by the source-review release gate
(every rule was researched through search summaries only) and by the human items in §10.

## 2. Jurisdiction
**Texas (Texas Workforce Commission)**, chosen over CA, NY, PA, FL and WA, with UK Universal Credit and Canada EI as controls
([docs/MARKET.md](docs/MARKET.md)). Reasons: many dated, letter-driven obligations on the claimant (3-day WorkInTexas registration,
a filing day every two weeks, a weekly work search log, 14-day appeals); TWC's claimant portal is not being replaced; NY is launching
a new UI system in 2026; CA changed its portal and identity checks in 2025–26.

## 3. Source and rule coverage
- Dataset `us_tx_ui` v`2026.09.25-1`: **23 rules** (21 official, 2 app suggestions), **9 letter types**, **6 help contacts**.
- Coverage: first steps, application, WorkInTexas, payment option, tax withholding, First Filing Date, payment requests every two weeks,
  work search (setup plus weekly log), identity verification, wage statement, determination appeal, hearing, Commission appeal, RESEA,
  replying to TWC requests, reporting new work, scam safety, Marketplace 60-day window, COBRA election.
- Source classes: TWC (state agency), HealthCare.gov / US DOL / DOJ / FTC (federal), Texas Law Help / TRLA (legal aid, never the sole source of an official rule).
- **Verification level: search summaries only (SNIPPET).** The network policy blocked direct access to government sites. **0 of 21 official
  rules are human-verified.** Six conflicts between sources were logged (SRD-01…06). The app resolves each one to the earlier date.
- Not covered: SNAP, Medicaid, CHIP, overpayments and waivers, severance effects, partial-unemployment details, Spanish content.

## 4. Product built (`app/`, Flutter 3.47.5)
Onboarding with the safety boundary and a Texas-only gate · Steps (Today / Next / Done plus a Next-deadline card) · step detail
(what to do, official source with review status, documents, when to get help, questions to ask, mark done / save proof) · Letters
(type, mailing date, printed deadline or appointment date, photo → step and deadline) · Log (submissions with confirmation numbers
and screenshots, a work search log using TWC's form fields with weekly counts, status notes copied word for word) · local reminders
(on the due day, plus 3 days and 1 day before hard deadlines, at 9:00 local time, safe across DST) · Timeline · question list ·
Get help · My dates · Export (text summary, JSON backup and photos through the share sheet) · Delete all · About (dataset version and
review status). Fully offline. No account, no server, no analytics, no ads.

Architecture: pure-Dart domain layer (LocalDate, rule schema, validator, resolver, reminder planner, export), a JSON file store
(atomic writes, backup copy, a guard against data from a newer app version), and a fallback mode that keeps records usable if the
dataset is invalid.

## 5. Safety boundary ([docs/SAFETY_BOUNDARY.md](docs/SAFETY_BOUNDARY.md))
The app does **not** decide eligibility, advise appeals, pose as TWC, submit anything, store credentials, promise payment, or
interpret disputed facts. This is enforced by the schema (no fields for separation reason, SSN or bank details), by the validator
(banned phrases, official-domain allow-list with lookalike domains rejected, `get_help` required), and by the UI (a persistent
"Not TWC" banner and an acknowledgement at onboarding). Tests cover all three.

## 6. Tests and builds
| Check | Result |
|---|---|
| `dart format --set-exit-if-changed` | Pass (local and CI) |
| `flutter analyze` | No issues (local and CI) |
| `flutter test` | **83 / 83 passing** (local and CI). Covers rule applicability, deadlines, weekly and every-two-weeks recurrence, time zones (Chicago DST, El Paso Mountain time), rule updates that keep completed tasks, invalid datasets (20 mutations), delete/export, and widget flows |
| Dataset validation (`tool/validate_dataset.dart`) | Pass |
| Release gate (`--release`) | **Fails as designed:** 21 official rules still need source review. It runs in CI as informational. |
| Android release APK (CI, debug-signed, not for the store) | **Pass.** CI run 2 produced the artifact `jobloss-os-android-apk-not-for-store` (~25 MB), kept for 14 days |
| iOS `--release --no-codesign` (CI, macOS) | **Pass** (CI run 2, macOS runner) |
| Local Android/iOS builds | Not possible here: no Android SDK, Google's download host was blocked, no macOS |
| On-device testing | **None performed** |

CI run (all jobs green): https://github.com/yantorres023/jobloss-os/actions/runs/36150165349

## 7. Business
Free for claimants, with no ads and no data sale. The sponsor hypotheses, ranked: employers through outplacement (outplacement
already costs about $500–$2,000+ per employee), outplacement firms, credit unions, unions, legal-aid funders, EAPs. State or workforce
boards are a possible future channel only. **No one was contacted.** See [docs/MONETIZATION.md](docs/MONETIZATION.md) and
[docs/GROWTH.md](docs/GROWTH.md). Direct competitors: WorkSearchLog (a paid Texas work-search tracker) and Claimyr (paid callback service).

## 8. Known knowledge gaps
- Exact current TWC page wording for every rule (all SNIPPET).
- Texas annual claim volume (FRED/TWC pages were blocked).
- Direct community evidence: Reddit was blocked. Community signals are weak and indirect (Claimyr's SEO Q&A pages, Trustpilot).
- Whether TWC's "calendar week" and work-search week both run Sunday to Saturday.
- RESEA changes under HB 3698 once the Chapter 815 rules are adopted.
- Share of claimants who prefer Spanish. Whether TWC plans a mobile app.
- No user interviews. No user behavior data.

## 9. SOURCE_REVIEW_REQUIRED
All 21 official rules and 6 help contacts ([docs/SOURCE_REVIEW_DEBT.md](docs/SOURCE_REVIEW_DEBT.md)), in priority order:
1. `tx.determination_deadline`, `tx.commission_appeal_deadline` (SRD-02, SRD-03: the appeal clock and holidays)
2. `tx.register_workintexas` (SRD-01: 3 days or 3 business days)
3. `tx.request_payment` (SRD-04), `tx.work_search_week` (SRD-05)
4. `tx.review_wage_statement` (SRD-06)
5. All remaining rules, the phone numbers and the URLs

## 10. HUMAN_ACTION_REQUIRED
1. Verify every source against the live page, set `verified` and `last_verified_at`, and get the release gate to pass.
2. Have an attorney review `legal/PRIVACY_POLICY_DRAFT.md` and `legal/TERMS_DRAFT.md` and fill in the entity and contact placeholders.
3. Have legal aid or UI experts review the appeal and deadline wording (FINAL_RED_TEAM H-5, H-15).
4. Decide the iOS backup policy for attachments (SECURITY.md).
5. Create an Android upload keystore, an Apple Developer account and signing; set bundle IDs (currently `org.joblossos.jobloss_os`).
6. Create an app icon. The current icon is the Flutter default and must not resemble TWC branding.
7. Test reminders on a device matrix (V-07). Test the app on real phones.
8. Decide on Spanish localization before public launch (V-09).
9. Run beta recruitment and sponsor discovery calls (V-01, V-05). The agent was not permitted to contact anyone.
10. Finish store listings using the rules in `docs/STORE_LISTING.md`. Host `landing/index.html`.

## 11. Beta gates (full detail in [docs/VALIDATION_DEBT.md](docs/VALIDATION_DEBT.md))
- **G-0** (enter closed beta): release gate passes, legal review done, CI green, reminders tested on at least 3 devices.
- **G-1** (week 2): no user believes the app is TWC, and no user acts on an app estimate instead of their letter.
- **G-2** (week 6): at least 80% pass the official-vs-suggestion comprehension check, and at least 90% choose the letter date when it conflicts with the app.
- **G-3** (week 8): a positive signal on missed deadlines (V-01) or on saving proof (V-03).
- **G-4** (public release): G-0 through G-3 pass and source-review staffing is in place.
- **G-5** (day 90): at least 2 sponsor letters of intent or pilots, or a grant.

**Kill / pivot triggers:** any missed appeal caused by an app date; TWC shipping equivalent features; review labor above 20 hours a month.

## 12. Next 3 experiments
1. **Comprehension and trust test (V-02, V-10):** 10–15 moderated sessions on the built app with Texas claimants recruited through a legal-aid
   partner. Pass: at least 80% correct on "who decides / which is a requirement / which date wins", and at least 90% choose the letter date.
2. **Source-review labor study (V-06):** one reviewer verifies all 21 rules and times it, then re-checks monthly for 3 months. Pass: under 8 hours a month.
3. **Sponsor discovery (V-05):** 10 conversations each with outplacement firms and Texas credit unions, using a one-page brief and the landing page.
   Pass: at least 2 letters of intent to fund a 90-day pilot with no data access.
