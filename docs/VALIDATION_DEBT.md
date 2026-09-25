# VALIDATION DEBT — JobLoss OS

Nothing about users has been validated: **no interviews, no users, no beta, no metrics exist.**

## Open questions → experiments

| ID | Question | Experiment | Success signal | Kill/pivot signal |
|---|---|---|---|---|
| V-01 | Does the roadmap reduce missed deadlines? | Beta (n≈40 TX claimants via legal aid/outplacement partner) vs. comparison group from same partner not using app; self-reported misses at 6 weeks | ≥30% fewer self-reported missed/late items | No difference, or app users report *more* confusion |
| V-02 | Do users understand official vs app explanation? | 5-item comprehension quiz on real screens (moderated, 10–15 people) | ≥80% correct on "who decides / which is a requirement / which date wins" | <60% → redesign; still <80% after redesign → STOP |
| V-03 | Do users actually save submission proof? | Beta exports (counts only, consented) | ≥60% of payment requests have proof | <25% → proof vault isn't the wedge; pivot to deadline-only |
| V-04 | Which portal statuses create most confusion? | Consented sharing of status notes; tag frequency | Top 5 statuses identified | — (informs content) |
| V-05 | Will employers/unions/credit unions sponsor it? | 10 discovery calls per segment (human-run), then 2 LOIs | ≥2 paid pilots or LOIs in 90 days | 0 LOIs after 30 conversations → grant-funded or sunset |
| V-06 | How often do rules change / how much review labor? | Log every source change and hours spent during 6 months | < 8 h/month for TX | > 20 h/month → cut rule scope to letters + deadlines only |
| V-07 | Do reminders arrive reliably? | Device matrix: Pixel, Samsung, Motorola (Android 12–15), iPhone iOS 17–19; 2 weeks | ≥95% delivered within 1 h of scheduled time | Unreliable on major OEM → add in-app calendar export (.ics) |
| V-08 | Market size in Texas | Pull TWC claims dashboard/FRED TXICLAIMS when network allows | Annual initial claims number with source | — |
| V-09 | Is Spanish required for launch? | Partner intake language stats | — | If >30% Spanish-preferred, Spanish is a launch blocker |
| V-10 | Do users trust the app more than letters? | In quiz: "App date vs letter date differ — which do you follow?" | ≥90% pick letter | <80% → stronger UI, or remove computed estimates |

## Beta gates

| Gate | Condition to enter beta / continue |
|---|---|
| G-0 (enter closed beta) | All 21 official rules human-verified (release gate passes); legal review of privacy/terms; CI green on Android + iOS; manual device QA of reminders on ≥3 devices |
| G-1 (week 2) | No safety incident: nobody believes the app is TWC; no one reports acting on an app estimate over their letter |
| G-2 (week 6) | V-02 ≥ 80%; V-10 ≥ 90% |
| G-3 (week 8) | V-01 or V-03 shows a positive signal |
| G-4 (public release) | G-0..G-3 pass; source review cadence staffed; incident process defined |
| G-5 (business, day 90) | ≥ 2 sponsor LOIs/pilots (V-05) or a grant |

## Kill / pivot triggers
- Any case of a user missing an appeal because of an app date → immediate pause of computed estimates; post-mortem.
- TWC launches an official app/portal feature covering letters + deadlines + proof → pivot to proof-vault/export for legal aid, or stop.
- Source review labor makes the dataset unmaintainable (V-06) → shrink to "letters + printed deadlines" only (pivot A).
