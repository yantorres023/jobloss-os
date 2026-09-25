# JobLoss OS

An unofficial, local-first mobile organizer (Flutter, Android and iOS) for people filing for unemployment benefits in **Texas**.
It helps answer: *What do I do today? What deadline is next? What did I already submit? Where is the official source? When do I
need a professional?*

**Not the Texas Workforce Commission. Not legal advice. Doesn't file anything, and doesn't decide eligibility.**

## Status
Pre-release. See [RELEASE_REPORT.md](RELEASE_REPORT.md). Rule sources still need **human review** before any public release
([docs/SOURCE_REVIEW_DEBT.md](docs/SOURCE_REVIEW_DEBT.md)).

## Repository map
| Path | Contents |
|---|---|
| `PROJECT_STATE.md`, `DECISIONS.md`, `RELEASE_REPORT.md` | Run state, decision log, final report |
| `docs/` | Research (SOURCES, EVIDENCE_LEDGER, MARKET, COMPETITORS, JTBD, RED_TEAM), product (PRD, UX_SPEC, SAFETY_BOUNDARY, RULE_ARCHITECTURE, ANALYTICS, TECHNICAL_PLAN, SECURITY), business (MONETIZATION, GROWTH, STORE_LISTING), debt (SOURCE_REVIEW_DEBT, VALIDATION_DEBT), FINAL_RED_TEAM |
| `legal/` | Privacy policy and terms **drafts** (need attorney review) |
| `landing/index.html` | Static landing page (no trackers) |
| `app/` | Flutter app; rules in `app/assets/rules/us_tx/rules.json` |
| `.github/workflows/ci.yml` | Format, analyze, test, dataset validation, Android APK, iOS no-codesign |

## Develop
```bash
cd app
flutter pub get
dart format --set-exit-if-changed lib test tool
flutter analyze
flutter test
dart run tool/validate_dataset.dart            # dataset validation
dart run tool/validate_dataset.dart --release  # release gate (fails until sources are human-verified)
```
