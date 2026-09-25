# EVIDENCE LEDGER — JobLoss OS

Every claim used to make a product decision, tagged by evidence class. Source IDs refer to [SOURCES.md](SOURCES.md).
All sources were seen as **search-index summaries**, not fetched pages (see SOURCES.md). No user interviews were conducted.

Classes:
- **OR** — OFFICIAL REQUIREMENT (agency says you must / failure has stated consequence)
- **OG** — OFFICIAL GUIDANCE (agency recommends / explains)
- **CE** — COMMUNITY EXPERIENCE (claimant reports, reviews, forum-like content)
- **INF** — INFERENCE (our reasoning from the above)
- **HYP** — HYPOTHESIS (untested; needs validation — see VALIDATION_DEBT.md)

## A. Texas claimant process

| # | Claim | Class | Sources | Conf. |
|---|---|---|---|---|
| A1 | Apply as soon as you are unemployed or hours are reduced; do not apply before your last workday. | OG | S03, S18 | Med |
| A2 | A Texas claim starts on the Sunday of the week you apply; backdating needs "good cause". | OR | S18 | Med |
| A3 | First week of a claim is an unpaid waiting week. | OR | S20 (glossary), S18 | Med |
| A4 | Register on WorkInTexas.com within 3 days of applying (one TWC checklist says "three business days"). | OR | S02, S07 | Med — wording conflict (SRD-01) |
| A5 | Request payment every two weeks on your scheduled filing day; if not requested within the calendar week it is due, payment may be delayed or denied. | OR | S02 | Med |
| A6 | Filing days are Sunday–Wednesday; "Instructions: Requesting Benefit Payments" letter shows First Filing Date and filing day. | OG | S02, S20 | Med |
| A7 | First payment request is ~1–2 weeks after applying. | OG | S02 | Med |
| A8 | Report gross earnings and hours worked for each week you request, even if above the weekly benefit amount. | OR | S12 | Med |
| A9 | Number of weekly work search activities is set by local Workforce Development Board and stated in a TWC letter along with its effective date; 3 is the common minimum; rural counties may be lower. | OR | S04, S05 | Med |
| A10 | Keep a work search log (date, employer/contact, type of contact, result); don't mail it unless asked; TWC may request any week's log during the benefit year and benefits can be lost if it can't be provided. | OR | S04, S06 | Med |
| A11 | Keep logs for the entire benefit year or as long as receiving benefits, whichever is longer. | OR | S04 | Med |
| A12 | Identity verification may be required via a TWC letter; options: ID.me online or in person at participating USPS. Not completing it delays/denies benefits. | OR | S10, S11 | Med |
| A13 | Review the Statement of Wages and Potential Benefit Amounts; call the Tele-Center (800-939-6631) about mistakes. | OG | S13 | Med |
| A14 | Appeal a determination in writing within 14 calendar days of the mailing date; the last day is printed on the form. Not by e-mail or phone. | OR | S08, S09, S24 | Med — one summary says "of receiving" (SRD-02) |
| A15 | If the 14th day falls on a holiday, deadline moves to next business day (stated for Commission appeals). | OR | S24 | Low — scope unclear (SRD-03) |
| A16 | Hearing packet arrives 5–10 days before the telephone hearing and explains how to submit documents. | OG | S24 | Med |
| A17 | Appeal of a hearing decision to the Commission: 14 days from mailing of that decision. | OR | S24 | Med |
| A18 | RESEA-selected claimants must complete orientation (video on WorkInTexas + assigned 1:1 appointment); repeated no-shows suspend eligibility. | OR | S14 | Med |
| A19 | TWC checklist after applying: WorkInTexas registration, payment option, work search log, able & available, request payment biweekly, tax withholding choice, read Handbook, respond when contacted. | OG | S07 | Med |
| A20 | Texas rules changed recently: HB 3698 (RESEA expansion, 2025) with proposed Chapter 815 rules (Apr 2026); HB 3699 changed "last work" definition for claims filed on/after 2026-01-01. | OR (law) | S15, S27, S28 | Med |
| A21 | TWC's claimant portal (UBS) is not being replaced now; the active modernization (TxUS) is the employer **tax** system. | OG | S29 | Low–Med |
| A22 | TWC Rapid Response and local boards engage workers on WARN/mass layoffs. | OG | S16, S17 | Med |

## B. Health coverage & safety (federal, used across states)

| # | Claim | Class | Sources | Conf. |
|---|---|---|---|---|
| B1 | 60 days after losing job-based coverage to apply for Marketplace coverage (Special Enrollment Period). | OR | S21 | Med |
| B2 | COBRA election period is 60 days from the later of coverage loss or election notice. | OR | S22 | Med |
| B3 | State workforce agencies do not text/e-mail invitations to apply; fake UI sites harvest PII. | OG | S23, S30 | Med |

## C. Pain / demand signals

| # | Claim | Class | Sources | Conf. |
|---|---|---|---|---|
| C1 | People pay $20–$60 for a service that waits on hold for them to reach a UI agency; reviews are largely positive. | CE | S61, S62 | Med (reviews may be curated) |
| C2 | A paid Texas-specific work-search tracker exists (WorkSearchLog; free trial, "Pro" plan), positioning on "TWC can ask for your full log any week". | CE/market | S60 | Med |
| C3 | Large volumes of SEO Q&A pages (Claimyr) answer TWC confusion questions (payment schedule, ID.me, late payment requests, backdating). These look machine-generated, so they show **what people search for**, not verified experiences. | CE (weak) | S61 | Low |
| C4 | Reddit could not be accessed; no direct community forum evidence was collected. | — | — | — |
| C5 | Official state UI apps exist in some states (MD, AZ) covering certification — the state channel is moving to mobile. | OG | S63, S64 | Med |

## D. Inferences & hypotheses

| # | Claim | Class | Basis |
|---|---|---|---|
| D1 | Texas has more **hard, dated, claimant-side obligations** that an organizer can track (3-day registration, biweekly filing day, weekly log, 14-day appeals) than CA/NY, while its claimant portal is not mid-migration. | INF | A4–A17, A21, S44–S47 |
| D2 | Deadlines are triggered by **letters with mailing dates**; the most valuable safe feature is "log the letter → see the deadline printed on it → reminder + proof." | INF | A12–A18 |
| D3 | All-state guides go stale because deadlines/rules change by statute (PA 15→21 days in 2021; TX HB 3698/3699 2025–26) and 50 states × many rules exceeds any small team's review capacity. | INF | S50, A20, S67 |
| D4 | Claimants will record proof (screenshots, confirmation numbers) if prompted at the moment of submission. | HYP | — |
| D5 | A free, local-first tool is more trustworthy than a paid one for a financially stressed user; revenue should come from sponsors (employers/outplacement, credit unions, legal aid funders). | HYP | C1, C2, S65 |
| D6 | Users can distinguish "official requirement" from "app suggestion" when labeled on every task. | HYP | — |
