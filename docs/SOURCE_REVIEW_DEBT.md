# SOURCE REVIEW DEBT — JobLoss OS

**Status: every rule is unverified.** Sources were seen only as search-engine summaries because the build environment's network
policy blocked the government sites (SOURCES.md). A person must open each official URL and confirm the rule text before any
public release. The release gate (`dart run tool/validate_dataset.dart --release`) fails until this is done.

## Per-rule review checklist (21 official rules)
For each: open URL → confirm the page exists and is current → confirm every factual sentence in `description` → confirm deadline
numbers → set `review.status=verified`, `last_verified_at=<date>` → bump `version` if text changes.

| Rule | Source | Specific things to confirm |
|---|---|---|
| tx.apply_for_benefits | S03, S18 | "don't apply before last day"; claim starts Sunday of week applied; backdating = good cause; document list |
| us.scam_safety | S23, S30 | Still-current federal advisory wording (2021 releases) |
| tx.register_workintexas | S02, S07 | **SRD-01** |
| tx.choose_payment_option | S07 | Payment options still direct deposit / debit card |
| tx.tax_withholding | S07 | Form/process name |
| tx.find_first_filing_date | S02 | Letter title; Tele-Serv number 800-558-8321 |
| tx.request_payment | S02, S12 | **SRD-04**; "calendar week" consequence wording; earnings reporting |
| tx.set_up_work_search | S04, S05 | Letter states number + effective date |
| tx.work_search_week | S04, S06 | **SRD-05**; retention wording; "don't mail unless asked" |
| tx.able_and_available | S07 | Wording |
| tx.read_handbook | S19 | Handbook URL is current edition |
| tx.report_work_when_rehired | S12 | Wording; fraud language |
| us.marketplace_window | S21 | 60-day SEP; Texas on HealthCare.gov for 2027 plan year |
| us.cobra_election | S22 | 60-day election from later of coverage loss / notice |
| tx.verify_identity | S10, S11 | ID.me + USPS options still offered; any standard deadline |
| tx.review_wage_statement | S13 | **SRD-06**; Tele-Center 800-939-6631 |
| tx.determination_deadline | S08, S09 | **SRD-02**, **SRD-03**; submission channels (online/mail/fax/in person; not phone/e-mail) |
| tx.prepare_for_hearing | S08 | Packet timing "5–10 days" came from legal-aid summary (S24) |
| tx.commission_appeal_deadline | S08 | 14 days from mailing of Appeal Tribunal decision; **SRD-03** |
| tx.resea_orientation | S14, S15 | Orientation video + 1:1; consequences; re-check after Ch. 815 RESEA rules adopted (HB 3698) |
| tx.respond_to_twc | S07 | Wording |

Help contacts to confirm: TWC Tele-Center 800-939-6631; TWC Tele-Serv 800-558-8321; TRLA 833-329-8752 and URL; Texas Law Help URL;
IdentityTheft.gov URL; HealthCare.gov URL.

## Conflicts found between summaries

| ID | Conflict | App behavior now | Resolve by |
|---|---|---|---|
| SRD-01 | WorkInTexas registration within "3 days" (S02) vs "3 business days" (S07) | Remind at applied + 3 **calendar** days (earlier) | Read both TWC pages; if business days, keep conservative date but change copy |
| SRD-02 | Appeal window "14 days from the mailing date" (S08/S09/S24) vs "within 14 days of receiving" (one summary) | Count from **mailing** date (earlier); printed date wins | TWC appeals page + a real determination form |
| SRD-03 | Holiday extension stated for Commission appeals; unclear for first-level appeals | Never extend | TWC appeals page / rules (40 TAC Ch. 815) |
| SRD-04 | "Calendar week" of a payment request assumed Sunday–Saturday | Late-after = Saturday of that week | TWC request payments page / handbook |
| SRD-05 | Work search week assumed Sunday–Saturday | Week = Sun–Sat | TWC handbook / work search log form |
| SRD-06 | 14-day window to dispute Statement of Wages (low confidence) | Remind at mailed + 14, labeled estimate | Statement form / TWC application-results page |

## Known un-sourced gaps (not in the app)
SNAP / Medicaid / CHIP coordination; severance or vacation pay effects; partial unemployment specifics; overpayment/waiver
process; Spanish content; RESEA details after 2026 rulemaking; TWC mobile channels. None of these are shown in v1.

## Ongoing review cadence (proposed)
Monthly check of all 21 official sources + event-driven check when TWC posts proposed/adopted rules (S28) or the Legislature passes
UI bills. Estimated effort to measure: V-06.
