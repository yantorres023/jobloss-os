# ANALYTICS — JobLoss OS

## Decision: no in-app analytics in v1 (D-012)
The app has **no analytics SDK, no crash reporter, no network calls**. Rationale: the data involved (layoff, letters, appeals,
health coverage) is sensitive; users are vulnerable; trust is the product. Any telemetry would need a privacy review we cannot
do autonomously.

## How we'll learn instead (beta)
| Question | Method | Data leaves device? |
|---|---|---|
| Do users understand official vs suggestion? | 5-question comprehension quiz in moderated beta sessions | Only what the participant tells us |
| Do users save proof? | Beta participants voluntarily share their **export** summary (counts only, redacted) | Only if the participant chooses |
| Missed deadlines? | Exit survey + comparison with a no-app cohort (V-01) | Survey answers only |
| Which statuses confuse? | Participants share status notes they logged (verbatim text) with consent | Only if shared |
| Reminder delivery | Device test matrix (Android 12–15 OEMs, iOS 17–19) | No |

## If telemetry is ever added (requirements)
Opt-in, off by default; aggregate counters only (e.g. "task completed" by rule_id, no dates, no text, no ids); no third-party SDK;
documented in the privacy policy; human privacy/legal review first.

## Candidate event list (for a future opt-in build — NOT implemented)
`onboarding_completed`, `task_completed{rule_id, kind, has_proof}`, `letter_logged{type, has_printed_deadline}`,
`deadline_passed_open{rule_id}`, `export_used`, `help_opened`.
