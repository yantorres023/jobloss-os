# PRD — JobLoss OS (Texas MVP)

## Problem
A newly laid-off Texan faces obligations scattered across mailed letters, TWC's portal/phone lines, WorkInTexas, identity
verification, and health-coverage deadlines. Several are short (3-day registration, 14-day appeals, a filing day every two weeks)
and some require records they must be able to produce later (work search log). Missing any can delay or cost benefits (EVIDENCE A4–A18).

## Promise
"After a layoff, know what you need to do next and keep proof of what you submitted." — for Texas, unofficially, privately.

## Users
Primary: someone laid off in Texas within the last ~4 weeks, on a phone, under financial stress.
Secondary: helpers (family, legal-aid staff, union reps) receiving the export.

## Goals (MVP)
1. Answer **What do I do today?** within 5 seconds of opening.
2. Answer **What deadline is next?** with its source and how the date was derived.
3. Answer **What did I already submit?** with confirmation numbers and screenshots.
4. Answer **Where is the official source?** on every step.
5. Answer **What needs a professional/agency?** on every official step.

## Non-goals
Eligibility, benefit calculation, filing, portal automation, account linking, chat/AI, other states, SNAP/Medicaid, job board.

## Scope (built)

| # | Feature | Status |
|---|---|---|
| 1 | Onboarding: safety boundary, Texas gate, last day worked, applied date, coverage end | Built |
| 2 | Texas versioned dataset (23 rules, 9 letter types, 6 help contacts) | Built — sources pending human review |
| 3 | Roadmap resolver (applicability, deadlines, recurrence, dependencies) | Built + tested |
| 4 | Steps: Today / Next / Done + Next-deadline card | Built |
| 5 | Step detail: what to do, official source + review status, documents, get-help, questions, mark done / save proof | Built |
| 6 | Letters: log letter type + mailing/printed/event dates + photo → task + deadline | Built |
| 7 | Log: submissions with confirmation # + screenshots; work search log (TWC fields) with weekly counts; verbatim status notes | Built |
| 8 | Reminders: local notifications (due day, −3/−1 for hard deadlines), 9:00 local, DST-safe | Built (device testing pending) |
| 9 | Timeline | Built |
| 10 | Export (text summary + JSON backup + photos via share sheet) | Built |
| 11 | Settings/privacy: reminders toggle, export, delete all | Built |
| 12 | Offline: 100% offline, no network calls except user-tapped links | Built |

## Success metrics (beta, see ANALYTICS.md — collected by opt-in survey, not tracking)
- ≥ 80% of beta users correctly distinguish "official step" vs "app suggestion" (comprehension test).
- ≥ 60% of payment-request completions include proof (confirmation # or screenshot).
- Self-reported missed deadline rate lower than a comparison group (V-01).
- Zero reports of users believing the app is TWC.

## Risks
See RED_TEAM.md and FINAL_RED_TEAM.md. Top: unverified sources; users trusting estimates over letters; reminder delivery.
