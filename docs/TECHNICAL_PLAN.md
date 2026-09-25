# TECHNICAL PLAN — JobLoss OS

## Stack
Flutter 3.47.5 (stable) / Dart 3.13. Android (minSdk from Flutter default, desugaring on) and iOS 15+.

| Concern | Choice | Why |
|---|---|---|
| State | `ChangeNotifier` controller + `InheritedNotifier` (`AppScope`) | Small app, zero extra deps |
| Storage | Single JSON document in app support dir; temp-file + rename; `.bak` copy; schema version guard | Local-first, trivially exportable, testable without platform plugins (D-013) |
| Dates | Custom `LocalDate` (no time/zone) | Deadlines are calendar dates; avoids DST/midnight bugs |
| Reminders | `flutter_local_notifications` + `timezone` + `flutter_timezone`; inexact alarms | No exact-alarm permission; 9:00 wall-clock in device zone |
| Attachments | `image_picker` → copied into private `attachments/` dir | User-owned proof, never uploaded |
| Export | `share_plus` share sheet (txt + json + images) | User chooses destination |
| Links | `url_launcher` external browser | Official pages open in the real browser (anti-phishing) |
| Rules | Bundled JSON asset + validator | No remote content in v1 |

## Layout
```
app/lib/
  domain/   local_date, rules (schema), dataset_validator, resolver, reminder_plan, user_data, export   ← pure Dart
  data/     store (FileStore, InMemoryStore)
  services/ reminders (plugin wrapper), export_service
  ui/       app_scope, theme, format, widgets/, screens/
  app_controller.dart, main.dart
app/assets/rules/us_tx/rules.json
app/tool/validate_dataset.dart
app/test/   83 tests
```

## Implementation order (as executed)
1 shell/local store → 2 dataset + validator → 3 resolver → 4 Today/Next/Done → 5 task detail/source → 6 letters + log + attachments →
7 reminders → 8 timeline → 9 export → 10 settings/privacy → 11 offline (inherent) / polish.

## Testing
`flutter test` covers: date math incl. DST; dataset validity + 20 invalid mutations; applicability; offset/notice/recurring/weekly
deadlines; conservative precedence; dependencies; buckets; next deadline; rule updates (version bump, deadline change, removal,
cadence change) preserving completions; reminder planning across DST (Chicago) and Mountain time (El Paso); cap and past-drop;
controller persistence; invalid-dataset fallback; attachment privacy (copy, delete, orphan purge); delete-all; export content and
JSON round-trip; FileStore corruption fallback and newer-version guard; widget flows (onboarding gate, home answers, step detail, letter → deadline).

## CI (`.github/workflows/ci.yml`)
checks (format, analyze, test, dataset validate, release gate informational) → Android release APK (debug-signed, artifact) → iOS `--no-codesign` on macOS.

## Known technical gaps
- No local Android/iOS build was possible in the authoring container (no Android SDK; Google download host blocked; no macOS). Builds rely on CI.
- Reminders not tested on devices (OEM battery policies).
- Tapping a notification opens the app but doesn't deep-link to the step yet.
- No app-level lock (PIN/biometric); relies on device lock. Candidate for v1.1.
- iOS backup: app support dir is included in iCloud/iTunes device backups by default (encrypted if user enabled). Android backup disabled. Decide per SECURITY.md.
