# UX SPEC — JobLoss OS

## Tone
The user may be scared about rent. Short sentences. No legal jargon without a plain explanation. Never alarmist, never
falsely reassuring. "TWC says…" when stating a rule. No exclamation marks, no gamification, no streaks.

## Five questions → where they're answered

| Question | Primary answer | Secondary |
|---|---|---|
| What do I do today? | Steps tab → **Today** list (overdue first) | Reminder notification |
| What deadline is next? | **Next deadline** card at top of Steps (red if passed) | Letters list shows each letter's deadline |
| What did I already submit? | Log → **Submitted** (confirmation #, screenshots) | Timeline; export |
| Where is the official source? | Step detail → **Official source** card (authority, host, looked-up date, human-check status, open button) | About screen |
| What needs a professional/agency? | Step detail → **When to get help** | More → Get help (situations list + contacts) |

## Information architecture
Bottom nav (4): **Steps** · **Letters** · **Log** · **More**. A persistent top strip: "Unofficial organizer · Not TWC · Not legal advice".
FAB "Add" on Steps opens: *I got a letter* / *I submitted something* / *I did a work search activity*.

## Key screens
1. **Onboarding** (single scroll): value line → "What this app is — and isn't" (4 points) → Texas / Another state →
   dates → acknowledgement checkbox → "Show my steps" (disabled until Texas + last day + checkbox).
2. **Steps**: Next-deadline card; segmented Today (n) / Next (n) / Done (n); task cards show title, date line
   ("Appeal deadline: Oct 5 (in 10 days)"), badge (Official step / App suggestion), warning icon if dates need checking.
3. **Step detail**: title, badges + "Source not yet human-checked"; When (date, basis text); warnings; letter card; What to do;
   inline inputs for setup facts (First Filing Date, work search number); weekly count for work search; What you'll need;
   Official source; When to get help; Questions (add to list); actions (Mark done / Done — save proof).
4. **Letters**: list + "Log a letter" form: type → type description → mailing date (help: "deadlines are often counted from this
   date, not when it arrived") → printed deadline ("always wins over the app's estimate") → note ("Don't type your SSN or PIN") → photo.
5. **Log**: tabs Submitted / Work search (grouped by Sunday–Saturday week, "2 of 3 recorded") / Status notes (verbatim).
6. **More**: Timeline, My questions, Get help, My dates, Privacy/export/delete, About (dataset version, count of steps pending review).

## Overload controls
- Today shows only due/overdue items; the rest sits in Next.
- Recurring items generate only a 28-day look-back and 35-day horizon.
- Reference rules ("stay able and available", "report work") sit in Next → "Anytime", never in Today.
- Dependencies hide follow-ups as "After: Apply…".

## Accessibility
Material 3 with system text scaling; semantic labels on status icons and banner; color is never the only signal (icons + text);
touch targets ≥ 48dp (Material defaults); dark mode.

## Language
English only in v1. Spanish is the top localization need for Texas (knowledge gap; TWC publishes Spanish materials, e.g. `-es-` PDFs
seen in search results). Tracked as V-09.
