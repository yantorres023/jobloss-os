# SAFETY BOUNDARY — JobLoss OS

This is a product contract. Code, dataset validation and store copy enforce it.

## The app MUST NOT

| Rule | How it is enforced |
|---|---|
| Decide legal eligibility | No eligibility logic exists. Profile has no separation reason, wages, or benefit amount fields (`knownFacts` in `lib/domain/rules.dart`). Dataset validator bans phrases like "you qualify", "you are eligible" (`bannedPhrases`). |
| Tell a user to appeal without basis | Appeal rules only show the deadline and who can advise. Banned phrases: "you should appeal", "you must appeal", "you will win". Test: `dataset_validation_test.dart` → "eligibility / legal-advice language is banned". |
| Represent itself as a state agency | Persistent banner "Unofficial organizer · Not TWC · Not legal advice" on every main screen; onboarding acknowledgement checkbox; neutral green palette, no seals/flags; store copy rules (STORE_LISTING.md). Banned phrases include "official app", "approved by TWC". |
| Submit claims automatically | No network code talks to any agency. The app has no HTTP client dependency. Links open in the external browser. |
| Store government credentials | No fields exist for passwords/PINs/SSN. Forms that accept free text show "Never your SSN, password or PIN". Test asserts dataset has no such fields. |
| Promise approval/payment | Banned phrases: "guaranteed", "you will be approved", "you will get paid". Copy says "TWC says payment may be delayed or denied" only where TWC says it. |
| Interpret disputed facts as law | The app never asks why the job ended. Letters are logged by type + dates; the app doesn't read or classify their content. Status notes are stored verbatim and never interpreted. |

## The app MAY

- Organize official steps (each with `official_or_suggested` label shown as a badge).
- Show the official source (title, authority, URL, last looked-up date, human-review status).
- Track dates and status the user enters.
- Store user-owned proof (photos/screenshots) privately on device.
- Remind about deadlines (local notifications; best-effort, with on-screen fallback).
- Help prepare a question list (suggested questions per step; user's own list).
- Explain official terms in plain language — only in rule text that sits next to its source.

## Date safety rules (D-008)

1. The date **printed on the user's letter** wins.
2. Otherwise, compute from the mailing date and label **"Estimated by the app … your letter wins"**.
3. When sources disagree (e.g., 3 days vs 3 business days), use the **earlier** date.
4. Never extend for weekends/holidays.
5. If a printed date is > 3 days later than the usual window, warn "Double-check".
6. A deadline that has passed is shown as passed, with "contact TWC or legal aid about what you can still do" — never "too late".

## Escalation ("needs a professional or the agency")

Every official rule carries `get_help` text (validator enforces). The Help screen lists: denial/determination, appeal/hearing,
overpayment, separation questions, wage disputes, anything about qualifying → TWC Tele-Center, Texas Law Help, TRLA.
