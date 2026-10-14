---
name: prepare-quarterly-report
description: Prepare, draft or catch up the LA City lobbying (Municipal Lobbying Ordinance, MLO) quarterly report, Form 34, or lobbying log from the user's Google Calendar and Gmail. Use when the user asks to prep, draft, update or catch up their lobbying report, MLO report, Form 34 or lobbying log for a quarter or month.
---

# Prepare the quarterly lobbying report (Form 34)

Draft the user's LA City Lobbying Firm Quarterly Report (Form 34) from their Google Calendar and Gmail, and save it as a draft with `save_report`. The user reviews it on the website and approves it there. You never approve or file a report.

Read both reference files before you scan anything:

- `references/mlo-rules.md`: the rules. Definitions, what counts as lobbying, what to exclude, which gray areas to ask about, and the known uncertainties with when to mention each.
- `references/form-34.md`: the format. What each Form 34 item maps to, the `content` JSON and its rules, one complete example, and wording guidance.

## The two tools

**`get_report { year?, quarter? }`**: pass both or neither.

- Both: returns that quarter's report as JSON `{ year, quarter, status, due_date, url, content, updated_at }`. If there is none it returns the plain text "No report for 2026 Q3." That is not an error. It means nothing is saved yet.
- Neither: returns the most recent report, or "No reports yet." if there are none.
- Errors: "Pass both year and quarter, or neither." and "Invalid year or quarter. Use a year from 2000 to 2100 and a quarter from 1 to 4."

**`save_report { year, quarter, content }`**: creates or replaces the DRAFT for that quarter. `year` and `quarter` are integers.

- Pass `content` as a JSON object (not a string) in the shape described in `references/form-34.md`.
- It replaces the whole draft, so every call must carry the complete report so far, never just the new items.
- It returns `{ status, url, counts: { clients, matters, contacts, excluded, open_items } }`.
- Errors come back as text. See "When save_report fails" below.

## First: check the connectors

Before anything else, confirm that you have working Google Calendar tools and Gmail tools, and that `get_report` and `save_report` are available. If Google Calendar or Gmail is missing or not connected (no such tool, or a sign-in or not-connected error), say which one and stop. Don't scan with only one of them, and don't guess what the missing one would show. If `get_report` or `save_report` is missing, say so and stop.

## Workflow

### 1. Pick the quarter

Default to the most recently ended quarter, using today's date in Los Angeles time (not UTC). That is last year's Q4 in January to March, Q1 in April to June, Q2 in July to September, and Q3 in October to December.

| Quarter | Period | Due (last day of the following month) |
|---|---|---|
| Q1 | Jan 1 to Mar 31 | Apr 30 |
| Q2 | Apr 1 to Jun 30 | Jul 31 |
| Q3 | Jul 1 to Sep 30 | Oct 31 |
| Q4 | Oct 1 to Dec 31 | Jan 31 of the next year (2026 Q4 is due Jan 31, 2027) |

- If the user names a quarter, month or date range, use that instead. A month belongs to the quarter that contains it. For "catch up September", the period is Sep 1 to Sep 30 and the report is that quarter's draft, which you resume and add to.
- A quarter still in progress is fine: scan up to today.
- If you can't tell today's date or which quarter is meant, ask.

State the period and the due date, then carry on. For example: "Preparing 2026 Q3, Jul 1 to Sep 30. Due Oct 31, 2026." If the due date has already passed, say so.

### 2. Load context

Call `get_report` with the year and quarter you picked, and act on the result:

- **A report with `status` "draft"**: resume it (a catch-up run). Keep everything in it: contacts, excluded items, payments, open items and disclosures. Its saved payment totals and disclosure answers may be out of date by now, so step 6 restates them for the user to confirm or update.
- **`status` "approved" or "filed"**: the report is locked and `save_report` will refuse it. Say so and stop without scanning. If it is approved, ask the user to reopen it on the website first. A filed report can't be reopened.
- **"No report for ..."**: call `get_report` with no arguments to get the latest report, and carry forward only its identity fields:
  - `firm`, `preparer` and `lobbyists`
  - each client's `name`, `address` and `phone`
  - each matter's `description` and `agencies`

  Never carry forward contacts, excluded items, payments, open items or disclosures across quarters. Start each client at `payments_total: null` and every disclosure at `unconfirmed` until step 6 answers them. Keep the carried-forward names exactly as written, so matching works.
- **"No reports yet."**: this is the first report. Ask once for the firm's name, address, email and phone, the preparer's name, address, email and phone, and the lobbyists' names. Don't invent any of it.

### 3. Scan sources

Scan the period you picked. Use Calendar and Gmail read-only.

**Calendar.** List all events in the period. For each, note the event ID, date, title, attendees (with their email domains) and location. Skip events that were cancelled, that the user declined, or that haven't happened yet. Read descriptions only to understand an event. Never copy them.

**Gmail.** Run targeted searches, and bound every query with `after:YYYY/MM/DD before:YYYY/MM/DD`. `before:` is exclusive, so use the day after the period ends:

```text
2026 Q3 (Jul 1 to Sep 30):   after:2026/07/01 before:2026/10/01
September 2026:              after:2026/09/01 before:2026/10/01
2026 Q4 (Oct 1 to Dec 31):   after:2026/10/01 before:2027/01/01
```

Search for each of these, each with the date bounds:

- `lacity.org`
- the department names and abbreviations in the agencies table in `references/mlo-rules.md` (you can combine them with OR)
- the case and permit patterns `CPC-`, `ZA-`, `DIR-`, `ENV-`, `VTT-`, `AA-`, and LADBS permit numbers (15 digits, usually written as three hyphenated groups of five). Gmail can't search a pattern, so also search the exact case and permit numbers in the carried-forward matter descriptions. Ignore hits that aren't City cases, since `AA-` also matches unrelated mail.
- `"Council District"`

Read metadata and snippets only: sender, recipients, date, subject and the snippet in the search result. Don't open message bodies, and never copy one into the report. If the metadata and snippet don't settle it, treat the item as an ask.

**Dates.** Every contact `date` and every excluded item `date` must fall inside the quarter, because `save_report` rejects any other. Take dates in Los Angeles time: an email sent at 6 pm on Sep 30 is Sep 30 even though its UTC timestamp says Oct 1. A month-by-month scan can pick up an Oct 1 item while building Q3. Leave it out. It belongs to the next quarter. For a Gmail thread, use the date of its first message inside the period.

**Large periods.** Work month by month, and treat a full quarter as large. Bound each month's searches by that month. Scan, classify and match one month (steps 3 to 5), then call `save_report`. Save after every month, including the last one, and always before you start the next month or ask the batch questions. Each save carries everything found so far, because `save_report` replaces the draft, and each save follows the open-item rules in step 7 (an unknown payment always gets its open item). For now, also put each undecided gray-area item in `open_items`, so nothing is lost if the session stops while you wait for answers. Ask your questions once, after the last month is saved (step 6).

### 4. Classify

Sort each item with the rules in `references/mlo-rules.md`:

- **Lobbying**: a direct communication with a City official or employee that tries to influence a discretionary matter. It becomes a contact.
- **Excluded**: not lobbying. Always record a reason. Examples: a ministerial action, an interpretation request, an internal or vendor meeting, a non-City agency. It goes in `excluded`.
- **Ask**: a gray area. Examples: LADBS "by right" or plan-check items, neighborhood council meetings, an unclear client, an unclear official or agency. Don't decide it yourself. Hold it for step 6.

Skip, without recording, anything with no link to the City, a client or a permit (personal events, unrelated meetings, mass mailings).

### 5. Match

Match each lobbying item to a client and a matter, reusing the existing names exactly.

- An unknown client or matter is an ask. Don't create one yourself, and don't guess its name (step 6 says how to ask).
- Use the firm person's name as it appears in `lobbyists`. Someone who isn't listed is an ask.
- Record one contact per calendar event or Gmail thread. An invitation or confirmation email for a calendar event is the same contact: record the event once. Skip anything whose `source_ref` is already in the draft's `contacts` or `excluded`, since a thread can turn up again in the next month's search.
- A carried-forward client, matter or agency with no contact this quarter stays in the draft (a matter keeps empty `contacts`). List those in one open item, so the user decides whether to keep or drop them.
- Make sure every contact's agency is in its matter's `agencies`. The one exception is a neighborhood council meeting the user confirms as lobbying: it is a contact whose `agency` is the council's name, but the council is never added to `agencies`, which lists City departments only.

### 6. Ask once, in a batch

Send one message with four parts, then wait for the reply.

1. **Gray areas.** A numbered list, one line per item: the date, what it was, and your suggested answer (lobbying for which client and matter, or not lobbying and why). Put unknown clients and matters here too, but never with a guessed name. Suggest a client only when the event or email itself shows it (the client's name, or an address or case number that matches a matter you already have), and say what shows it. Otherwise ask "which client is this for?" and suggest nothing. Treat a new matter the same way: use only what the item shows. For a new client, also ask for its address and phone.
2. **Payments.** The total each client paid the firm this quarter (fees, reimbursements and anything else received). "Don't know" is an acceptable answer.
3. **Other disclosures.** One yes/no question on the six topics below (Form 34 items C5, C6 and C8 to C13; C7 is asked separately in part 4; see `references/form-34.md`): this quarter, did the firm or its lobbyists have any expense of $25 or more that benefited a City official (gifts, meals, travel or anything else; C5), make City campaign contributions, raise funds for City officials or candidates, make payments or donations at a City official's request (behested), do paid campaign work, or hold a City contract?
4. **Lobbying expenses (C7).** The quarter's total expenses to influence City legislation: payments to the firm's lobbyists and to other employees for their lobbying work, plus other expenses attributable to lobbying, excluding overhead. Any single item of $5,000 or more is listed separately. "None" and "don't know" are both acceptable answers.

**Resuming a draft (a catch-up run).** Its data stays, but don't keep its payment totals and disclosure answers silently: new activity or payments can make them stale. Ask the gray-area items the draft doesn't already settle. For parts 2 to 4, restate what is saved in one line each and ask "still right?", so the user can confirm or update it: each client's saved payment total, the saved answers on the six topics (with any `details`), and the saved C7 answer. A saved `null` payment or an `unconfirmed` disclosure isn't an answer yet, so ask for it as you would on a first run.

A first-run message:

```text
2026 Q3 scan done (Jul 1 to Sep 30). Before I save the draft I need a few answers.
Reply by number, or "ok" to accept all my suggestions (a question needs your answer).

Gray areas
1. Aug 14: call with a Building and Safety plan checker about corrections to the
   300 Sample Boulevard permit. Suggest: not lobbying (ministerial action).
2. Aug 27: Example Neighborhood Council meeting on Sample Apartments. Suggest: record as
   lobbying for Sample Housing Partners LP (Sample Apartments is its matter).
3. Sep 18: email thread with a City planner about a site plan on Sample Terrace.
   No client or case number shown. Which client is this for?

Payments received this quarter (fees, reimbursements, anything else; "don't know" is fine)
- Example Bistro Group LLC:
- Sample Housing Partners LP:

Other disclosures
This quarter, did the firm or its lobbyists have any expense of $25 or more that benefited
a City official (gifts, meals, travel or anything else), make City campaign contributions,
raise funds for City officials or candidates, make payments or donations at a City
official's request, do paid campaign work, or hold a City contract? Reply "no" if none.

Lobbying expenses (C7)
Total expenses this quarter to influence City legislation: payments to the firm's lobbyists
and to other employees for their lobbying work, plus other expenses attributable to
lobbying, excluding overhead. List any single item of $5,000 or more separately.
"None" or "don't know" is fine.
```

A catch-up message, when the draft already holds the answers:

```text
2026 Q3 catch-up done (Sep 1 to Sep 30). The draft already holds these answers, so please
check them. Reply "ok" to keep every saved value, and answer any line that asks a question.

Payments received this quarter (saved)
- Example Bistro Group LLC: $12,500. Still right?
- Sample Housing Partners LP: unknown. What was the total? ("don't know" is fine)

Other disclosures (saved)
- None on any of the six topics (expenses of $25 or more that benefited a City official,
  campaign contributions, fundraising, behested payments, campaign work, City contracts).
  Still right?

Lobbying expenses (C7) (saved)
- $31,000. Still right?
```

Don't ask again if something goes unanswered. Record it as an open item in step 7.

### 7. Save

Build the complete `content` (see `references/form-34.md`) and call `save_report`. Apply the answers from step 6:

- **Gray areas:** "lobbying" becomes a contact (for a neighborhood council, the contact's `agency` is the council's name and the council stays out of `agencies`; see step 5). "Not lobbying" becomes an excluded item with its reason. No answer becomes an open item.
- **Additions:** a contact the user tells you about that is in neither Calendar nor Gmail gets `source_type` `manual` (see `references/form-34.md`).
- **Payments:** a plain number of dollars (no `$` or commas) goes in `payments_total`. "Don't know" gives `null`. Never use `0` for an unknown amount.
- **Other disclosures (the six topics):** "no" sets `activity_expenses`, `contributions`, `fundraising`, `behested_contributions`, `behested_donations`, `campaign_services` and `city_contracts` to `none`. "Yes" sets the ones the user names to `reported` with a one-line `details`, and the rest of those seven to `unconfirmed`. No answer sets all seven to `unconfirmed`.
- **Lobbying expenses (C7):** only this answer sets `lobbying_expenses`. The yes/no never does. A total gives `reported`, with the total (and any single item of $5,000 or more) in `details`. An explicit "none" gives `none`. "Don't know" or no answer gives `unconfirmed`, plus an open item asking for the C7 total.
- **Catch-up run:** for each saved payment total, disclosure answer and C7 answer you restated, "still right" keeps the saved value and a new value replaces it.

Anything unresolved goes into `open_items`:

- **Unknown payments.** Every client with `payments_total: null` needs its own open item that names the client. Write the name exactly as it is in the client's `name`, because `save_report` refuses the report when no open item contains it.
- **Unknown lobbying expenses (C7).** If `lobbying_expenses` is `unconfirmed`, add an open item asking for the C7 total.
- **Clients below the $250 registration threshold.** Keep the client, and add an open item asking the user to confirm that it belongs in the report.
- **Unanswered questions.** Gray-area items with no answer, other disclosures that are `unconfirmed`, and clients with a missing address or phone. On a catch-up run, also any saved payment total or disclosure answer the user neither confirmed nor updated: say that it wasn't reconfirmed.
- **Carried-forward clients, matters or agencies with no contact this quarter** (step 5).

Rebuild `open_items` on every save. Drop what is now resolved, and don't repeat an item that is already there.

### 8. Report back

Tell the user, briefly:

- the counts from the last `save_report` result: clients, matters, contacts and excluded items
- the open items, as a list
- the URL from `save_report`, with "review and approve here."

Don't paste the whole report. Mention an uncertainty from section 5 of `references/mlo-rules.md` only if it bears on this report. End with the reminder: "This is a draft, not legal advice."

```text
Saved the 2026 Q3 draft: 2 clients, 2 matters, 5 contacts, 2 excluded items.
Open items (2):
- Sample Housing Partners LP: total payments for 2026 Q3 are unknown.
- Aug 27 Example Neighborhood Council meeting: not recorded; confirm whether to report it.
Review and approve here: <url from save_report>
This is a draft, not legal advice.
```

## When `save_report` fails

Errors come back as text. Act on each:

- **"Report content is invalid:"** followed by one `- <path>: <message>` line per problem, for example `clients[0].matters[0].contacts[0].summary: max 200 chars`. Fix every listed path and call again. Date errors, such as `clients[0].matters[0].contacts[0].date: 2026-10-01 is outside 2026 Q3 (2026-07-01 to 2026-09-30)` (an excluded item's looks like `excluded[0].date: ...`), and unknown-payments errors, such as `clients[0].payments_total: unknown payments need an open item that names "Example Bistro Group LLC"`, only show once the rest of the content is valid, so a retry can list new ones. Repeat until it saves. For a date error, check the item's real date in Los Angeles time. Correct it if you misread it, and remove the contact or excluded item if it truly belongs to another quarter. For an unknown-payments error, add an open item that names that client. If the same error comes back after you fix it, tell the user what it says and stop.
- **"Report 2026 Q3 is approved and locked. Ask the user to reopen it on the website."**: tell the user to reopen the report on the website, and retry once they say they have.
- **"Report 2026 Q3 is filed and locked."**: a filed report can't be changed or reopened. Tell the user and stop.
- **"The report changed while you were working. Reload and try again."**: call `get_report` for that quarter, check that it is still a draft, merge your changes into its content and save again.
- **"Server error: ... Try again; if it repeats, tell the user."**: retry once. If it fails again, tell the user.

## Guardrails

- Never invent officials, clients, matters, case numbers, addresses or payments, or what was said or decided. Use `""` for a missing address, email, phone or official title and `null` for unknown payments, and add an open item.
- When unsure, ask or add an open item. Don't guess.
- Keep every `summary` to one line of at most 200 characters, in your own words. Never put an email body, a quote from one, or a pasted snippet into the report.
- Use Gmail and Calendar read-only. Never send, draft, label, move or delete anything.
- Don't approve or file anything. The user does that on the website.
- Remind the user that the result is a draft and not legal advice. Flag the uncertainties in section 5 of `references/mlo-rules.md` only when they are relevant.
