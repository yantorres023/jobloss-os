# MARKET & JURISDICTION SELECTION — JobLoss OS

Evidence classes and source IDs: see [EVIDENCE_LEDGER.md](EVIDENCE_LEDGER.md), [SOURCES.md](SOURCES.md).

## 1. Context

- US initial UI claims were ~197,000/week (seasonally adjusted, week ending 2026-09-19) (S01). California, Texas and New York
  consistently appear among the largest week-to-week movers (S01). State-level annual Texas totals could not be retrieved
  (FRED/TWC pages blocked) — **knowledge gap**.
- Each US state runs its own UI program, portal, notices and deadlines. There is no single national process to organize.

## 2. Candidates compared

Scores 1 (bad for us) – 5 (good for us). "Value-add" = how much an organizer can help **without touching the government account**.

| Criterion | Texas (TWC) | California (EDD) | New York (NYSDOL) | Pennsylvania | Florida | Washington | Canada EI (control) | UK UC (control) |
|---|---|---|---|---|---|---|---|---|
| Claim volume | 5 | 5 | 4 | 3 | 3 | 3 | n/a | n/a |
| Documented claimant pain | 4 (ID.me, late payment requests, phone access; Claimyr exists) | 5 | 5 | 3 | 4 | 3 | 2 | 3 |
| Official docs quality (as seen via search) | 4 (checklist PDF, handbook, log form, county table) | 4 | 4 | 4 | 3 | 4 | 4 | 4 |
| Rule / portal stability now | 3 (HB 3698/3699 changes; claimant portal not migrating) | 2 (myEDD + ID verification vendor changes 2025–26) | 1 (new UI platform launching in 2026) | 4 | 3 | 4 | 4 | 3 |
| Hard claimant-side deadlines to track | 5 (3-day WIT, filing day, weekly log, 14-day appeals) | 3 (bi-weekly cert, 30-day appeal) | 4 (weekly cert, 3 activities/week record, 30-day hearing) | 4 (weekly cert, 21-day appeal, 2 apps+1 activity) | 4 (bi-weekly, 5 contacts, 20-day appeal) | 4 (weekly, 3 activities, 30-day appeal) | 3 | 2 (journal in official portal) |
| Value-add without automation | 5 | 3 | 3 (value may shift after migration) | 4 | 4 | 4 | 3 | 1 (official journal already does task log) |
| Competition | 3 (WorkSearchLog targets TX work search; Claimyr pages) | 2 (heavy SEO/content) | 2 | 4 | 3 | 4 | 4 | 3 |
| Legal risk | 4 (short deadlines raise stakes; mitigated by "use date on your notice") | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| Update burden | 4 (single agency, few notice types) | 2 | 1 | 4 | 3 | 4 | 4 | 3 |
| Distribution | 4 (large employer base, WARN data, Rapid Response, 2 large legal aid orgs) | 4 | 4 | 3 | 3 | 3 | 2 | 2 |
| **Total** | **41** | 34 | 32 | 37 | 34 | 37 | — | — |

Controls: **UK Universal Credit** shows what "the portal already does everything" looks like — the official UC journal is a
to-do list, message channel and upload area (S54 and related). A third-party organizer adds little there. **Canada EI** has a
simple bi-weekly report with a 3-week window (S53) — low deadline pressure → low value. Both support the thesis that value
exists only where the official system scatters obligations across letters, sites and deadlines — the US state model.

## 3. Decision: **Texas** (D-004)

Why Texas beats California and New York despite their size:
1. **New York** is launching a new UI platform in 2026 with no public go-live date (S47). Building screen-level guidance now
   would be stale on arrival.
2. **California** changed its portal (myEDD) and identity verification vendor path in 2025–26 (S42) and has heavy free content competition.
3. **Texas** obligations are claimant-side, dated, and letter-driven — exactly what an organizer can hold safely (D1, D2).
   The claimant portal (UBS) is not being replaced (A21). TWC publishes an official checklist, log form and county table
   the app can link rather than restate.

Why not Pennsylvania/Washington (close scores): smaller volume and distribution; kept as expansion candidates to test
dataset portability (see VALIDATION_DEBT.md).

## 4. Why broad 50-state guides go stale (explicit research question)

- Deadlines change by statute (PA appeal window 15 → 21 days, Act 30 of 2021, S50). Texas passed two UI-process bills in
  2025 with rules following in 2026 (A20). Across 50+ jurisdictions, **several changes per year are expected** (INF).
- Portal migrations (NY 2026, CA myEDD) invalidate screenshots and click-paths wholesale.
- Generic multi-state sites observed (S67) present state rules in uniform templates; several summaries we saw differed from
  each other on basics (e.g., appeal clock "from mailing" vs "from receipt") — the same class of error a user would act on.
- Economics: a small team can keep **one** state's ~20 rules reviewed monthly. 50 states × ~20 rules = ~1,000 rules — not
  reviewable without a staff (see VALIDATION_DEBT V-06 to measure real labor).

**Conclusion:** narrow, state-specific, versioned, source-per-rule is superior for correctness. It is worse for SEO reach and
TAM — accepted trade-off (D-005).

## 5. Sizing (honest)

We could not retrieve Texas annual claims counts; we do not publish a TAM number. Proxy: Texas is the 2nd-largest state by
population and employers (S-secondary via search) and WARN notices listed tens of thousands of affected Texas workers in 2026
(warnact.io summary, unverified). Sizing is a **validation debt** item (V-08).
