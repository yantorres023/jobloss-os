# SOURCES — JobLoss OS

## How these sources were gathered (read first)

- Research date: **2026-09-25**.
- The build environment's network policy **blocked direct fetches** of every government site tried
  (`twc.texas.gov`, `edd.ca.gov`, `dol.ny.gov`, `dol.gov`, `oui.doleta.gov`), and also of Reddit,
  legal-aid sites and the Internet Archive. Only a web **search index** was reachable.
- So every source below was seen as a **search-result summary of the page**, not the page itself.
  That is recorded as `verification: SNIPPET`.
- **No source here has been human-verified.** Every rule in the app dataset that cites one of these carries
  `review.status = "snippet_only"` and is listed in [SOURCE_REVIEW_DEBT.md](SOURCE_REVIEW_DEBT.md).
- Search summaries sometimes disagreed with each other (e.g., "3 days" vs "3 business days", "14 days from
  mailing" vs "14 days of receiving"). Those conflicts are logged in SOURCE_REVIEW_DEBT.md. The app always
  uses the **earlier / more conservative** reading and tells the user to check the date printed on their notice.

Authority classes: `STATE_AGENCY` (official state UI agency), `STATE_LEGISLATURE`, `FEDERAL_AGENCY`,
`LEGAL_AID` (non-profit legal services), `SECONDARY` (law firms, publishers, blogs), `COMPETITOR`, `NEWS`.

## Texas (chosen jurisdiction)

| ID | Title | URL | Authority | Verification |
|---|---|---|---|---|
| S01 | DOL Unemployment Insurance Weekly Claims (national/state) | https://www.dol.gov/ui/data.pdf | FEDERAL_AGENCY | SNIPPET |
| S02 | TWC — Request Benefit Payments | https://www.twc.texas.gov/programs/unemployment-benefits/request-benefit-payments | STATE_AGENCY | SNIPPET |
| S03 | TWC — Apply for Unemployment Benefits | https://www.twc.texas.gov/services/apply-benefits | STATE_AGENCY | SNIPPET |
| S04 | TWC — Work Search Requirements | https://www.twc.texas.gov/programs/unemployment-benefits/work-search-requirements | STATE_AGENCY | SNIPPET |
| S05 | TWC — Required Number of Work Search Activities by County | https://www.twc.texas.gov/programs/unemployment-benefits/required-number-work-search-activities-county | STATE_AGENCY | SNIPPET |
| S06 | TWC — Work Search Log (PDF form) | https://www.twc.texas.gov/sites/default/files/ui/docs/work-search-log-twc.pdf | STATE_AGENCY | SNIPPET |
| S07 | TWC — Checklist: After You Apply for Unemployment Benefits (PDF) | https://www.twc.texas.gov/sites/default/files/ui/docs/checklist-after-apply-benefits-twc.pdf | STATE_AGENCY | SNIPPET |
| S08 | TWC — Introduction to the Unemployment Benefits Appeal Process | https://www.twc.texas.gov/programs/unemployment-benefits/appeals-process | STATE_AGENCY | SNIPPET |
| S09 | TWC — File an Unemployment Appeal | https://www.twc.texas.gov/services/file-unemployment-appeal | STATE_AGENCY | SNIPPET |
| S10 | TWC — Identity Verification (unemployment benefits) | https://www.twc.texas.gov/programs/unemployment-benefits/identity-verification | STATE_AGENCY | SNIPPET |
| S11 | TWC news — In-person identity verification at USPS locations | https://www.twc.texas.gov/news/texans-now-able-verify-identity-person-unemployment-benefit-claims-usps-locations | STATE_AGENCY | SNIPPET |
| S12 | TWC — Report Your Work & Earnings | https://www.twc.texas.gov/programs/unemployment-benefits/report-your-work-earnings | STATE_AGENCY | SNIPPET |
| S13 | TWC — Learning the Result of Your Application for Benefits | https://www.twc.texas.gov/programs/unemployment-benefits/application-results | STATE_AGENCY | SNIPPET |
| S14 | TWC — Reemployment Services & Eligibility Assessment (RESEA) | https://www.twc.texas.gov/programs/reemployment-services-eligibility | STATE_AGENCY | SNIPPET |
| S15 | TWC — Proposed rules, Chapter 815 (RESEA, HB 3698), 2026-04-14 (PDF) | https://www.twc.texas.gov/sites/default/files/ogc/docs/pr-815-resea-4-14-26-twc.pdf | STATE_AGENCY | SNIPPET |
| S16 | TWC — Preventing & Managing Layoffs (Rapid Response) | https://www.twc.texas.gov/employer-resources/preventing-managing-layoffs | STATE_AGENCY | SNIPPET |
| S17 | TWC — WARN Notices | https://www.twc.texas.gov/data-reports/warn-notice | STATE_AGENCY | SNIPPET |
| S18 | TWC — Basics of Applying for Unemployment Benefits | https://www.twc.texas.gov/programs/unemployment-benefits/basics-of-applying | STATE_AGENCY | SNIPPET |
| S19 | TWC — Unemployment Benefits Handbook (PDF) | https://www.twc.texas.gov/sites/default/files/ui/docs/unemployment-benefits-handbook-twc.pdf | STATE_AGENCY | SNIPPET |
| S20 | TWC — Unemployment Benefit Services (UBS) FAQ | https://apps.twc.texas.gov/UBS/afbfaq.do | STATE_AGENCY | SNIPPET |
| S21 | HealthCare.gov — See your options if you lose job-based health insurance | https://www.healthcare.gov/have-job-based-coverage/if-you-lose-job-based-coverage/ | FEDERAL_AGENCY | SNIPPET |
| S22 | US DOL EBSA — FAQs on COBRA Continuation Health Coverage for Workers | https://www.dol.gov/agencies/ebsa/about-ebsa/our-activities/resource-center/faqs/cobra-continuation-health-coverage-workers | FEDERAL_AGENCY | SNIPPET |
| S23 | US DOJ — Justice Department Warns About Fake Unemployment Benefit Websites | https://www.justice.gov/archives/opa/pr/justice-department-warns-about-fake-unemployment-benefit-websites | FEDERAL_AGENCY | SNIPPET |
| S24 | Texas Law Help — Unemployment Benefits Appeals in Texas | https://texaslawhelp.org/article/unemployment-benefits-appeals-in-texas | LEGAL_AID | SNIPPET |
| S25 | Texas RioGrande Legal Aid — Public Benefits | https://www.trla.org/public-benefits | LEGAL_AID | SNIPPET |
| S26 | Texas Law Help — Unemployment Benefits | https://texaslawhelp.org/article/unemployment-benefits | LEGAL_AID | SNIPPET |
| S27 | Vensure — Texas Unemployment "Last Work" Rule for 2026 (HB 3699 summary) | https://vensure.com/employment-law-updates/texas/texas-unemployment-last-work-rule-for-2026/ | SECONDARY | SNIPPET |
| S28 | TWC — Proposed and Recently Adopted Rules | https://www.twc.texas.gov/agency/laws-rules-policy/rules/rules-proposed-adopted | STATE_AGENCY | SNIPPET |
| S29 | TWC — TxUS UI Tax Modernization external communication (PDF) | https://www.twc.texas.gov/sites/default/files/ui/docs/txus-1st-external-communication.pdf | STATE_AGENCY | SNIPPET |
| S30 | FTC — Scammers reportedly using fake unemployment benefits websites | https://consumer.ftc.gov/consumer-alerts/2021/03/scammers-reportedly-using-fake-unemployment-benefits-websites-phishing-lures | FEDERAL_AGENCY | SNIPPET |

## Comparison jurisdictions (used for selection only; not in the app dataset)

| ID | Title | URL | Authority | Verification |
|---|---|---|---|---|
| S40 | CA EDD — Step 5: Certify for Benefits | https://edd.ca.gov/en/unemployment/step-5-certify-for-benefits/ | STATE_AGENCY | SNIPPET |
| S41 | CA EDD — Appeal Form DE 1000M | https://edd.ca.gov/siteassets/files/pdf_pub_ctr/de1000m.pdf | STATE_AGENCY | SNIPPET |
| S42 | CA EDD — Makes online identity verification easier (2026) / Socure in myEDD | https://edd.ca.gov/en/newsroom/benefitting-californians/benefiting-californians-2026/edd-makes-online-identity-verification-easier/ | STATE_AGENCY | SNIPPET |
| S43 | CA EDD — Work Search Requirement information notice | https://edd.ca.gov/en/jobs_and_training/Information_Notices/wsin21-07/ | STATE_AGENCY | SNIPPET |
| S44 | NY DOL — When should I certify? | https://dol.ny.gov/when-should-i-certify | STATE_AGENCY | SNIPPET |
| S45 | NY DOL — UI Work Search Requirements and Recordkeeping | https://dol.ny.gov/services/ui/wsr | STATE_AGENCY | SNIPPET |
| S46 | NY UI Appeal Board — Request a Hearing | https://uiappeals.ny.gov/request-hearing | STATE_AGENCY | SNIPPET |
| S47 | Citizen Portal — NY labor chief says new unemployment system will launch this year (2026) | https://citizenportal.ai/articles/7505568/new-york/2026-legislature-ny/state-labor-chief-says-new-unemployment-system-will-launch-this-year-aims-to-cut-wait-times | NEWS | SNIPPET |
| S48 | PA — File a Weekly UC Certification | https://www.pa.gov/services/dli/file-a-weekly-unemployment-compensation-certification | STATE_AGENCY | SNIPPET |
| S49 | PA — Appeal a UC Decision (Claimants) | https://www.pa.gov/services/dli/appeal-an-unemployment-compensation-decision--claimants- | STATE_AGENCY | SNIPPET |
| S50 | PA General Assembly — Act 30 of 2021 (appeal period 15 → 21 days) | https://www.legis.state.pa.us/cfdocs/legis/li/uconsCheck.cfm?yr=2021&sessInd=0&act=30 | STATE_LEGISLATURE | SNIPPET |
| S51 | FloridaCommerce — After Applying for Benefits | https://floridajobs.org/workforce-resources/reemployment-assistance/claimants/after-applying-for-benefits | STATE_AGENCY | SNIPPET |
| S52 | WA ESD — Job search requirements | https://esd.wa.gov/get-financial-help/unemployment-benefits/weekly-unemployment-claims/job-search-requirements | STATE_AGENCY | SNIPPET |
| S53 | Canada.ca — Employment Insurance reporting | https://www.canada.ca/en/services/benefits/ei/employment-insurance-reporting.html | FEDERAL_AGENCY (CA) | SNIPPET |
| S54 | GOV.UK — Universal Credit and your claimant commitment | https://www.gov.uk/government/publications/universal-credit-and-your-claimant-commitment-quick-guide/universal-credit-and-your-claimant-commitment | FEDERAL_AGENCY (UK) | SNIPPET |

## Competitors, market and community

| ID | Title | URL | Authority | Verification |
|---|---|---|---|---|
| S60 | WorkSearchLog — Texas Work Search Tracker | https://worksearchlog.com/ | COMPETITOR | SNIPPET |
| S61 | Claimyr — Texas Unemployment pages (callback service + SEO Q&A) | https://claimyr.com/government-services/texas-twc-unemployment/ | COMPETITOR | SNIPPET |
| S62 | Trustpilot — Claimyr reviews | https://www.trustpilot.com/review/claimyr.com | COMMUNITY | SNIPPET |
| S63 | Google Play — MD Unemployment for Claimants (official state app) | https://play.google.com/store/apps/details?id=gov.maryland.ui.claimant&hl=en_US | STATE_AGENCY | SNIPPET |
| S64 | App Store — Arizona Unemployment (official state app) | https://apps.apple.com/us/app/arizona-unemployment/id6741441973 | STATE_AGENCY | SNIPPET |
| S65 | Careerminds — How much does outplacement cost? | https://careerminds.com/blog/how-much-does-outplacement-cost | SECONDARY | SNIPPET |
| S66 | AARP — 6 things to know about fake unemployment websites | https://www.aarp.org/money/scams-fraud/fake-unemployment-websites/ | SECONDARY | SNIPPET |
| S67 | Generic "all-state" guide sites (theunemployment.org, unemploymentcalculator.org, remotelaws.com) | various | SECONDARY | SNIPPET |
| S68 | FRED — Initial Claims in Texas (TXICLAIMS) | https://fred.stlouisfed.org/series/TXICLAIMS | FEDERAL (Fed. Reserve) | SNIPPET (numbers not retrieved) |
