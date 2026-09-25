# SECURITY & PRIVACY REVIEW — JobLoss OS

## Data inventory
| Data | Where | Sensitivity | Notes |
|---|---|---|---|
| Key dates (last day worked, applied, filing, coverage end) | JSON in app support dir | Medium | |
| Work search count | same | Low | |
| Letters: type, dates, free-text note | same | Medium–High | Note field warns against SSN/PIN |
| Submissions: kind, date, confirmation #, note | same | Medium | Confirmation numbers are not credentials |
| Work search log (employers, contacts) | same | Medium | Third-party contact info entered by user |
| Status notes, questions | same | Medium | |
| Photos/screenshots of letters | `attachments/` in app support dir | **High** (letters may show name, address, claim ID, partial SSN) | Never leaves device unless user exports |
| **Never collected**: SSN, passwords, PIN, bank/card, benefit amounts, separation reason | — | — | Enforced by schema + tests |

## Threats and mitigations
| Threat | Mitigation | Residual |
|---|---|---|
| Server breach | No server exists | — |
| Lost/stolen unlocked phone | Device lock; data in app-private storage | No in-app lock (v1.1 candidate) |
| Cloud backup exposure | Android `allowBackup=false`, `fullBackupContent=false` | iOS: included in device backups by default → **decision needed** (HUMAN_ACTION_REQUIRED) |
| Phishing via the app (fake links) | Links only from validated dataset (official allow-list, https, lookalike rejected); open in system browser; copy teaches "TWC won't text you a link" | User could still be phished elsewhere |
| Malicious dataset update | No remote datasets in v1; bundled + validated | Future: signed datasets |
| Export leaks | Export only via user-initiated share sheet; temp export dir cleared on delete-all | Once shared, outside our control (explained in UI) |
| Deleted photos lingering | Delete letter/entry deletes files; orphan purge on load; delete-all removes dir | OS-level file recovery out of scope |
| Data corruption | Atomic write + backup file; corrupt file → backup → fresh | Loss possible if both corrupt |
| Downgrade overwrites newer data | `NewerDataVersionException` blocks saving | — |
| Notification content on lock screen | Titles are step names (e.g. "Appeal deadline in 1 day") | Could reveal unemployment status to onlookers → setting to hide content (v1.1) |
| Third-party SDKs | Only Flutter first-party/community plugins for notifications, images, share, links, path, timezone; no analytics/ads | Supply chain: pinned via pubspec.lock |

## Permissions
Android: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` (reschedule after reboot). No exact alarms, no location, no contacts, no internet-dependent features (the INTERNET permission is present in Flutter debug builds only by default; release uses none of it except user-tapped links handled by the browser).
iOS: camera and photo library usage strings (only when user attaches), notifications on opt-in.

## Open items (HUMAN_ACTION_REQUIRED)
1. Decide iOS backup policy (exclude attachments from backup vs. keep for user's benefit).
2. Pen-test/static review before public release.
3. Legal review of privacy policy draft (legal/PRIVACY_POLICY_DRAFT.md).
4. Release signing keys (Android upload key, Apple distribution).
