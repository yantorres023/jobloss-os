# RULE ARCHITECTURE — JobLoss OS

## Principles
- **Data, not reasoning.** Rules are JSON records. No LLM, no free-form inference, no eligibility logic.
- **Source per rule.** Every active official rule cites an https URL on an allow-listed official domain with an official authority class.
- **Versioned.** Dataset has `dataset_version`; each rule has `version`. Completions store both, so the user's history is auditable after updates.
- **Honest review state.** `review.status` ∈ `verified | snippet_only | needs_review`; `last_verified_at` is null until a human checks the page. Today all rules are `snippet_only` (see SOURCES.md).
- **Fail closed.** A dataset that fails validation is not loaded; the app falls back to record-keeping mode (Letters/Log still work) — pivot A from RED_TEAM.md.

## File
`app/assets/rules/us_tx/rules.json` — one file per jurisdiction.

## Rule schema (v1)

| Field | Meaning |
|---|---|
| `rule_id` | Stable dotted id (`tx.request_payment`). Never reused for a different meaning. |
| `version` | Integer, bump on any change to text, deadline or applicability. |
| `jurisdiction` | `US-TX` or `US` (federal). |
| `title`, `description` | Plain language (target ≤ 8th grade). |
| `category` | `first_steps`, `claim_setup`, `ongoing`, `letters`, `appeals`, `health`, `reference`. |
| `applies_to.requires_facts` | Profile facts that must be set (dates/counts the user entered). |
| `applies_to.requires_notice` | Notice type; one task instance per logged letter of that type. |
| `official_or_suggested` | `official` requires official source; `suggested` = app advice, labeled as such. |
| `source` / `additional_sources` | `{source_id, title, url, authority}`. |
| `last_checked_at` | Date the source was last looked at (any method). |
| `last_verified_at` | Date a human verified it against the live page. Null until done. |
| `review` | `{status, notes}` — notes reference SOURCE_REVIEW_DEBT ids. |
| `effective_from` / `effective_to` | Rule only applies within this window (supports law changes like TX HB 3699 on 2026-01-01). |
| `deadline` | See below. |
| `documents_needed` | What to have ready. |
| `depends_on` | Single-instance rules that must be done first (shows as "After: …"). |
| `completes_with_fact` | Entering this fact marks the step done (e.g. entering `applied_date` completes "Apply"). |
| `questions_to_ask` | Suggested questions the user can add to their list. |
| `get_help` | When to go to TWC/legal aid. Required for official rules. |
| `active` | Kill switch. |

### Deadline types

| Type | Computation | Example |
|---|---|---|
| `none` | No date ("Anytime") | Read the handbook |
| `asap` | Due the day the rule starts applying (latest required fact date) | Apply for benefits |
| `offset` | `from_fact + days` (calendar) | WorkInTexas: applied + 3 |
| `notice` | printed deadline → event date → mailed + `fallback_days_from_mailed` (estimate) → logged date (asap) | Appeal: mailed + 14 |
| `recurring` | `from_fact + k·every_days`, until `until_fact`; `late_after: end_of_calendar_week` sets hard deadline to that Saturday | Payment request every 14 days |
| `weekly` | One per Sunday–Saturday week from `from_fact` | Work search log |

`hard: true` = official consequence if missed → counted in "Next deadline", reminders at −3, −1, 0 days.

### Instance keys (stable across updates)
- single: `rule_id`
- per notice: `rule_id@noticeId`
- recurring/weekly: `rule_id#YYYY-MM-DD`

Completions are keyed by instance key. If a rule disappears, its completions remain and appear under Done as "no longer in the current rules" (`orphanCompletions`).

## Validation (`lib/domain/dataset_validator.dart`, run in tests and CI)
Schema version; unique ids; id format; jurisdiction; non-empty text; official source rules (authority + https + allow-listed domain,
lookalike domains rejected); dates valid, `last_checked_at ≤ published_at`, `verified ⇒ last_verified_at`; effective window order;
known facts/notice types; deadline-type-specific checks; dependency existence, single-instance targets, no cycles; banned
eligibility/legal-advice phrases; `get_help` required for official rules.

## Release gate
`dart run tool/validate_dataset.dart --release` fails while any active official rule is not `verified`. CI runs it as informational.
**No store release until it passes** (HUMAN_ACTION_REQUIRED).

## Update process (future)
1. Reviewer opens each source URL, confirms text, sets `review.status=verified`, `last_verified_at`, bumps `version` if text changes.
2. Bump `dataset_version`, `published_at`.
3. CI validates; ship with an app update (v1 has no remote rule download — avoids a remote-content attack surface; revisit later with signed datasets).
