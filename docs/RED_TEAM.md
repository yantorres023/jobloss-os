# RED TEAM — JobLoss OS (pre-build)

Goal: try to kill the idea. Each attack gets evidence, a verdict and what survives.

| # | Attack | Evidence | Verdict | What survives / mitigation |
|---|---|---|---|---|
| RT-1 | **The state portal already does everything.** | UBS lets you apply, request payment, check status, submit a log when asked (S20). TWC publishes a checklist (S07) and a log form (S06). UK UC shows a portal *can* do everything (S54). | **Partly true.** For the actions themselves, yes. | TWC's obligations arrive by **mailed letters** with mailing-date clocks, a biweekly filing day, a paper log, and separate sites (WorkInTexas, ID.me/USPS, HealthCare.gov). Nothing official ties them together with reminders and proof on the phone. The app must never duplicate actions — only organize them. |
| RT-2 | **Rules change too often.** | TX HB 3698/3699 (2025) + proposed Ch. 815 rules (2026) (A20); PA 15→21 days (S50); NY portal replacement (S47). | **True in general; manageable for one state.** | Single state; ~20 rules; versioned dataset; every rule has `last_checked_at` and review status; app shows "check official page" on every task; deadlines come from the **user's own letter** whenever possible, so a stale rule text can't silently move a date. |
| RT-3 | **Users need a lawyer/agency staff for edge cases.** | Appeals, separation disputes, overpayments, wage disputes involve facts and law (S24, S25). | **True.** | App refuses those decisions. "Needs a professional or TWC" section per task routes to TWC Tele-Center, Texas Law Help, TRLA/LSLA. Separation reason is **not collected** (D-007). |
| RT-4 | **Summaries create dangerous errors.** | Our own research found conflicting summaries: "3 days" vs "3 business days" (A4); "14 days from mailing" vs "of receiving" (A14). A user trusting the later reading could miss an appeal. | **True — the most serious risk.** | (a) Conservative rule: always compute the **earlier** date; (b) primary input is "the last day printed on your notice"; computed dates are labeled *estimate*; (c) no rule ships as "verified" until a human checks the source (SOURCE_REVIEW_DEBT); (d) plain-language text never states a number without the source link beside it. |
| RT-5 | **Users only need it briefly.** | Texas benefits last a limited number of weeks; most users churn at re-employment. | **True.** | That's fine for a free, sponsored product: value per episode, not retention. It kills subscription B2C though (see RT-6). Export at the end preserves the value. |
| RT-6 | **Monetization is unethical or weak.** | Users are income-shocked. Claimyr charges per call (C1); WorkSearchLog runs freemium (C2). Charging for deadline reminders to people at risk of losing income is ethically weak, and paywalling a safety feature (appeal reminders) is unacceptable. | **B2C paid: STOP.** | Free for claimants, forever, with no ads and no data sale. Revenue hypothesis moves to sponsors (employers' layoff packages/outplacement at ~$500–$2,000/employee budgets (S65), credit unions, legal-aid funders, unions). Unproven → VALIDATION_DEBT V-05. |
| RT-7 | **A free website is enough.** | Guides exist (S67, S24). | **Partly true for information; false for personal dates/proof.** | A website can't hold your letters, compute your dates or remind you on your filing day without an account. Local-first mobile does that with zero server data. A landing page is still built for distribution. |
| RT-8 | **Claimants may trust it more than official sources.** | Polished apps feel authoritative; fake UI sites exist (S23, S30). | **Real risk.** | No state seal/colors/"TX" logos; persistent "Not TWC" label; every step shows the official source button and "the official page and your letter win"; store copy forbids government-implying words; the app never asks for SSN, passwords or bank details — and says so, which also teaches phishing hygiene. |
| RT-9 | **A state app will ship and make this obsolete.** | MD and AZ have official apps (S63, S64). | **Possible.** | Our layer (letters, proof, cross-agency deadlines like health coverage) remains; reminders would dedupe. Monitor (R-1). |
| RT-10 | **Liability if a reminder fails (OS kills notifications).** | Android/iOS can drop scheduled notifications (battery optimization, permission denied). | **Real.** | Deadlines are always visible on the Today screen without notifications; notification permission status shown; disclaimer that reminders are best-effort. |

## Pivots considered (within layoff admin + checklist + proof + deadlines + status organization)

- **Pivot A — "Proof vault only"** (no rule content; user types their own deadlines). Safest, but loses "what do I do today?"
  which is the stated core job. Rejected as primary; **kept as the fallback mode**: every rule-driven feature degrades to
  user-entered dates if the dataset is ever pulled.
- **Pivot B — "Notice decoder"** (only interpret letters). Too close to legal interpretation of disputed facts. Rejected.

## Verdict: **GO (narrow, conditional)**

GO for a **free, local-first, Texas-only** organizer whose rules are official-sourced, versioned and conservative, and whose
deadlines prefer the user's own notice. Conditions (beta kill gates in VALIDATION_DEBT.md):
1. No public release until every active official rule passes human source review (release gate script).
2. B2C payment is off the table.
3. If beta users can't tell "official requirement" from "app suggestion" (≥80% correct), redesign or stop.
