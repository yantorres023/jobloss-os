# FINAL HARM / FAILURE RED TEAM — JobLoss OS (post-build)

Reviewed against the built app on 2026-09-25. Severity: **H** high, **M** medium, **L** low.

| # | Failure / harm scenario | Sev | Current mitigation in build | Residual risk → action |
|---|---|---|---|---|
| H-1 | A rule's text is wrong because it came from a search summary, and the user acts on it | H | Every step shows "Source not yet human-checked" + official link; About shows count pending; release gate blocks store release | **Blocks release** until SOURCE_REVIEW_DEBT is cleared |
| H-2 | User enters the wrong mailing date → appeal reminder too late | H | Printed deadline field is primary and "always wins"; computed dates labeled estimate; −3/−1/0 reminders | Can't prevent typos. Beta V-10. Consider asking for a photo before showing a computed appeal date |
| H-3 | Reminder silently not delivered (OEM battery killers, permission denied) | H | Deadlines always visible on Steps; settings copy says reminders are best-effort | Device QA (V-07); add .ics calendar export if unreliable |
| H-4 | User thinks the app is TWC and misses the real portal step | H | Persistent banner, onboarding acknowledgement, no seals/colors, copy "you apply on TWC's own site" | Comprehension test V-02 |
| H-5 | Passed deadline displayed in a way that makes user give up ("too late") | M | Copy says "check your letter and contact TWC or legal aid about what you can still do"; TWC allows late appeals with good cause per summaries (not stated in app since unverified) | Legal-aid review of wording |
| H-6 | Payment-request cadence drifts (TWC changes filing day, user misses because app shows old schedule) | M | User can edit First Filing Date any time; copy says TWC letter/UBS is the source | Add "my filing day changed" hint in step |
| H-7 | Work search count shown as "2 of 3" read as compliance judgement | M | Explicit "a count of what you recorded, not a decision about your claim"; number comes from user's letter | V-02 |
| H-8 | Sensitive photos exposed via device backup (iOS) or shared export | M | Android backup off; export only by user; delete-all clears export cache | iOS backup decision (HUMAN_ACTION_REQUIRED) |
| H-9 | Lock-screen notification reveals unemployment/appeal to others | L–M | None yet | v1.1: "hide notification details" setting |
| H-10 | Dataset bug crashes app, locking user out of their records | M | Invalid dataset → fallback record-keeping mode; tests cover | — |
| H-11 | Downgrade/reinstall wipes data | M | Newer-version guard; export; copy warns that uninstall deletes data | — |
| H-12 | Employer sponsor influences content in disputed separations | M (future) | Policy in MONETIZATION.md: identical content, zero data to sponsor | Contract terms (human) |
| H-13 | Spanish-speaking claimants excluded | M | None (English only) | V-09 before public launch |
| H-14 | User enters SSN/PIN in free-text notes | L | Helper text warns; data stays local | Could add pattern detection (###-##-####) warning |
| H-15 | Health-coverage estimates wrong for edge cases (COBRA later-of rule) | M | Copy explains later-of rule and "notice wins"; estimate from mailing date only | Review with benefits expert |

## Verdict
The build honors the safety boundary. It is **not safe for public release** today, only because of H-1 (unverified sources) plus
the device-level unknowns in H-3 and the missing reviews in H-8 and H-13. It is suitable for a closed, supervised beta after G-0.
