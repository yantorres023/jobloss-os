# MONETIZATION — JobLoss OS

**No one was contacted. Nothing here is validated. All figures are cited secondary data or hypotheses.**

## B2C paid: rejected (D-010)
- Users just lost income. Charging to be reminded of deadlines that protect their income is ethically weak, and paywalling
  appeal reminders is unacceptable.
- The need lasts weeks, not years (RT-5) → subscription churn is structural.
- Evidence people *do* pay: Claimyr ($20–$60 per call, S61/S62) and WorkSearchLog's paid tier (S60). That shows willingness to pay
  for **access to a human at the agency**, which we don't offer, and it doesn't make charging for safety features right.
- Decision: the claimant app is free forever, with no ads and no data sale. That is also a trust asset for distribution partners.

## Sponsor models (hypotheses, ranked)

| # | Payer | Why they might pay | Model | Evidence | Risks |
|---|---|---|---|---|---|
| 1 | **Employers (via outplacement/severance packages)** | Layoff "soft landing" and employer brand; outplacement already budgets ~$500–$2,000+/employee (S65) | Per-layoff-event license, e.g. $5–$20/seat added to an outplacement bundle; white-label "provided by [employer]" splash — **never** changes content | S65 (cost benchmarks) | Employer–claimant conflict of interest in disputed separations → content must stay identical and the employer gets **zero** data |
| 2 | **Outplacement firms** | Adds a benefits-admin module they lack | Reseller/licensing | INF | Same conflict rules |
| 3 | **Credit unions** | Member financial hardship programs; members at risk of delinquency | Sponsorship per member/year or flat state license | HYP | Must not upsell loans in-app |
| 4 | **Unions** | Member services during layoffs | Flat sponsorship | HYP | Small TX union density (knowledge gap) |
| 5 | **Legal-aid / civic-tech funders (foundations)** | Access-to-justice outcomes; fewer missed appeal deadlines | Grants covering source-review labor | S24–S26 show legal aid's focus on UI appeals | Grant cycles; requires outcome data (V-01) |
| 6 | **EAP providers** | Add to life-event resources | Licensing | HYP | EAP procurement is slow |
| 7 | State/workforce boards (Rapid Response, S16) | Distribution on WARN events | **Future only; not assumed.** Procurement, conflict with official tools | S16, S17 | Could look like government endorsement — must not |

## Cost side (to be measured, V-06)
Main recurring cost is **human source review** (~23 rules for TX; initial full review + monthly re-check + event-driven re-check on
TWC rule changes). Engineering and store fees are small. Hosting: none (local-first).

## What would make us stop
If no sponsor category shows willingness to pay within the beta window (VALIDATION_DEBT gate G-5), keep the app as a free open
tool with grant funding or sunset it — do not introduce ads or B2C paywalls.
