# DECISIONS — JobLoss OS

Format: `D-### | date | decision | rationale | reversibility`

- D-001 | 2026-09-25 | Create PROJECT_STATE.md and DECISIONS.md before any research. | Mission requirement; keeps autonomous run auditable. | n/a
- D-002 | 2026-09-25 | All research docs live in `docs/`; app lives in `app/`; top-level holds state/decision/release files. | Keeps Flutter project isolated and CI paths simple. | Easy
- D-003 | 2026-09-25 | Research uses search-index summaries only; mark every source `SNIPPET` and every rule `snippet_only`. | Network policy blocked direct fetches of government sites; fabricating verification is forbidden. | Easy — re-verify when access exists
- D-004 | 2026-09-25 | Initial jurisdiction: **Texas (TWC)**. | Highest score in MARKET.md: many dated claimant-side obligations, claimant portal not migrating, NY portal replacement in 2026, CA identity/portal churn. | Medium
- D-005 | 2026-09-25 | Narrow single-state product over a 50-state guide. | Staleness evidence (PA Act 30, TX HB 3698/3699, portal migrations); review labor scales with rule count. | Medium
- D-006 | 2026-09-25 | Verdict **GO (narrow, conditional)**; pivots A/B evaluated and rejected (A kept as fallback mode). | See docs/RED_TEAM.md. | —
- D-007 | 2026-09-25 | Do not collect separation reason, SSN, passwords, bank details, or benefit amounts. | Separation reason invites eligibility inference; credentials/PII create breach and phishing risk. | Hard to reverse once collected — so don't
- D-008 | 2026-09-25 | Deadline precedence: (1) date printed on user's notice, (2) computed from user-entered mailing/trigger date labeled "estimate", conservative (earlier) reading when sources conflict; never extend for holidays/weekends. | RT-4: summaries conflict; an early reminder is harmless, a late one is not. | Easy
- D-009 | 2026-09-25 | Work search minimum comes from the user's TWC letter (entered by user), not a county table in-app. | County numbers change and are set by local boards; the letter is authoritative for that claimant. | Easy
- D-010 | 2026-09-25 | Free for claimants; no ads; no data sale; revenue hypothesis = sponsors (employers/outplacement, credit unions, legal-aid funders, unions). | RT-6 ethics. | Medium
- D-011 | 2026-09-25 | Health-coverage deadlines (Marketplace SEP, COBRA election) included from federal sources; SNAP/Medicaid excluded from v1. | Federal sources found and simple; SNAP/Medicaid rules not researched to safe depth. | Easy
- D-012 | 2026-09-25 | No analytics/crash SDK in v1; learn via consented beta surveys and exports. | Sensitive data, vulnerable users; privacy review not possible autonomously. | Easy
- D-013 | 2026-09-25 | Storage = one JSON document (atomic write + backup) instead of SQLite. | Small data volume, trivial export, pure-Dart testability. | Medium (migration if data grows)
- D-014 | 2026-09-25 | Rules bundled with the app; no remote dataset download in v1. | Removes remote-content attack surface; updates ship via app releases. | Easy
- D-015 | 2026-09-25 | Recurring items generate 28-day look-back / 35-day horizon; completed past items always kept. | Avoid burying mid-claim users in overdue items without losing history. | Easy
- D-016 | 2026-09-25 | Inexact Android alarms at 9:00 local; no exact-alarm permission. | Day-level deadlines; avoids a sensitive permission and store scrutiny. | Easy
