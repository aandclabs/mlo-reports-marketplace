# Form 34 content: items, field rules, example and wording

This is the shape of the `content` object you pass to `save_report`. It follows the ordinance's list of required contents (LAMC § 48.08(C)) item by item. Every name, address, case number and ID in the example below is made up.

Contents: 1. Form 34 items (C1 to C16) and where each goes. 2. Field rules. 3. Complete example (2026 Q3). 4. Guidance: matter descriptions, contact summaries, `source_ref`, excluded `reason`, `open_items`.

## 1. Form 34 items (C1 to C16) and where each goes

| Item | What the ordinance requires | Where it goes in `content` |
|---|---|---|
| C1 | Firm name, address, email, phone | `firm` |
| C2 | Each lobbyist who is a partner, owner, shareholder, officer or employee of the firm | `lobbyists[]` |
| C3 | For each client required to be registered: name, address, phone; each item of municipal legislation lobbied for that client this quarter; total payments received from that client (fees, reimbursements, other) | `clients[]`: `name`, `address`, `phone`; `matters[].description` for each item of legislation, with its `agencies` and the `contacts` that are the evidence; `payments_total` |
| C4 | Total payments from all such clients | Not stored. The website adds up each client's `payments_total` and marks unknown amounts as unknown (for example "$12,500.00 + 1 unknown"), never as $0 |
| C5 | Each activity expense of $25 or more (date, amount, description, official who benefited, payee, client) | `other_disclosures.activity_expenses` |
| C6 | Total activity expenses | `other_disclosures.activity_expenses` (same key as C5) |
| C7 | Total expenses to influence municipal legislation: payments to the firm's lobbyists, payments to non-lobbyist employees who lobbied, other attributable expenses excluding overhead (items of $5,000 or more itemized) | `other_disclosures.lobbying_expenses`. The skill asks for it on its own: the yes/no on the other six topics never sets it |
| C8 | Contributions of $100 or more made, delivered or intermediated to elected City officers, candidates or their committees | `other_disclosures.contributions` |
| C9 | Fundraising for City officers or candidates (dates, amount raised) | `other_disclosures.fundraising` |
| C10 | Contributions totaling more than $1,000 made at the behest of a City officer or candidate to other City committees | `other_disclosures.behested_contributions` |
| C11 | Charitable or nonprofit donations totaling $1,000 or more made at the behest of a City officer or candidate | `other_disclosures.behested_donations` |
| C12 | Compensated services to a City candidate or ballot-measure campaign | `other_disclosures.campaign_services` |
| C13 | Compensated services under a City contract | `other_disclosures.city_contracts` |
| C14 | Each City agency attempted to influence (applies only to an individual contract lobbyist acting as a firm) | Not captured. The departments lobbied are recorded for every matter in `agencies` anyway |
| C15 | Name, address, email and phone of the person preparing the report | `preparer` |
| C16 | Anything else the Ethics Commission requires by regulation | Not captured |

Two parts of `content` are not Form 34 items. `excluded` is the audit trail of items you reviewed and judged not to be lobbying. `open_items` lists the gaps the user must resolve before approving.

Form 34 does not list individual meetings. It rolls up by client: the matters lobbied, the departments lobbied and the payments. The `contacts` are the evidence behind that rollup.

## 2. Field rules

`save_report` checks `content` against these rules and refuses it if any fails. All seven top-level keys are required; the arrays may be empty.

| Path | Rule |
|---|---|
| `firm`, `preparer` | `{ name, address, email, phone }`. `name` is required; the other three are strings and may be `""` if unknown. |
| `lobbyists[]` | `{ name }`, required. |
| `clients[]` | `name` is required. `address` and `phone` are strings. `payments_total` is a number of 0 or more, or `null` for unknown, and the key must always be present. A `null` also needs an open item that names the client (see the notes below). `matters[]` is an array. |
| `matters[]` | `description` is required. `agencies` is an array of strings naming City departments, offices and commissions, never a neighborhood council. `contacts[]` is an array. |
| `contacts[]` | `date` is `YYYY-MM-DD` and must fall inside the quarter. `lobbyist`, `official_name` and `agency` are required. `official_title` is a string. `mode` is one of `meeting`, `call`, `email`, `hearing`, `other`. `summary` follows the summary rule. `source_type` is one of `calendar`, `gmail`, `manual`. `source_ref` is required. |
| `summary` (contacts and excluded) | 1 to 200 characters, on one line (no line breaks). |
| `other_disclosures` | All eight keys are required: `activity_expenses`, `lobbying_expenses`, `contributions`, `fundraising`, `behested_contributions`, `behested_donations`, `campaign_services`, `city_contracts`. Each is `{ status, details? }`, where `status` is `none`, `reported` or `unconfirmed` and `details` is an optional string. |
| `excluded[]` | `{ date, summary, reason, source_ref }`. `date` is `YYYY-MM-DD` and must fall inside the quarter. `reason` and `source_ref` are required. |
| `open_items[]` | `{ text }`, required. |

Notes:

- `payments_total`: `0` means the client paid nothing. `null` means unknown. Never use `0` for an unknown amount, and give every `null` its own open item. `save_report` refuses a `null` unless some open item contains the client's name (capitalization doesn't matter), so write the name exactly as it is in `name`, as the example below does.
- `mode`: `meeting` is in person or by video, `call` is by phone, `email` is for a Gmail thread, `hearing` is an appearance at a public hearing, `other` is anything else.
- `other_disclosures` statuses: `none` means the user confirmed there is nothing, `reported` means there is something (put a one-line summary in `details`), `unconfirmed` means it is not answered or not known. The website does not itemize disclosures, so the user itemizes them when filing.
- `lobbying_expenses` (C7) is a total. Only the user's answer about C7 sets it, never the yes/no on the other six topics. A total is `reported`, with the total (and any single item of $5,000 or more) in `details`. An explicit "none" is `none`. "Don't know" or no answer is `unconfirmed`, with an open item asking for the total.
- `agencies` lists the City departments, offices and commissions lobbied on that matter, using the short names in `references/mlo-rules.md`. Include the `agency` of each contact that is with a City agency. The one exception is a neighborhood council meeting the user confirmed as lobbying: it is a contact whose `agency` is the council's name, and the council is never added to `agencies`.
- `lobbyist` on a contact is the firm person who made it, named exactly as in `lobbyists`.
- `official_name` is the name shown in the invite or email header. If only an address is shown, use the address. Never invent a name. Use `""` for an unknown `official_title`.
- Unknown keys are dropped silently, so an extra field never reaches the report.
- Contact dates and excluded item dates are both checked against the quarter. A date outside it is refused with its path, for example `excluded[0].date: 2026-10-01 is outside 2026 Q3 (2026-07-01 to 2026-09-30)`.

## 3. Complete example (2026 Q3)

In this example the user answered "no" to the other-disclosures question, gave $31,000 as the total for lobbying expenses (C7), and does not know what the second client paid.

```json
{
  "firm": {
    "name": "Sample Land Use Advisors LLC",
    "address": "100 Example Street, Suite 400, Los Angeles, CA 90000",
    "email": "reports@example.com",
    "phone": "213-555-0100"
  },
  "preparer": {
    "name": "Pat Preparer",
    "address": "100 Example Street, Suite 400, Los Angeles, CA 90000",
    "email": "pat.preparer@example.com",
    "phone": "213-555-0101"
  },
  "lobbyists": [{ "name": "Lee Lobbyist" }, { "name": "Jordan Sample" }],
  "clients": [
    {
      "name": "Example Bistro Group LLC",
      "address": "200 Sample Avenue, Los Angeles, CA 90000",
      "phone": "213-555-0102",
      "payments_total": 12500,
      "matters": [
        {
          "description": "Conditional use permit for Example Bistro on-site alcohol, 300 Sample Boulevard (ZA-2026-0001-CUB)",
          "agencies": ["City Planning", "Council District 13"],
          "contacts": [
            {
              "date": "2026-07-15",
              "lobbyist": "Lee Lobbyist",
              "official_name": "Morgan Planner",
              "official_title": "City Planner",
              "agency": "City Planning",
              "mode": "meeting",
              "summary": "Meeting with Morgan Planner about the Example Bistro CUP",
              "source_type": "calendar",
              "source_ref": "example-event-0001"
            },
            {
              "date": "2026-08-04",
              "lobbyist": "Lee Lobbyist",
              "official_name": "Taylor Deputy",
              "official_title": "Planning Deputy",
              "agency": "Council District 13",
              "mode": "email",
              "summary": "Email thread with Taylor Deputy about the Example Bistro CUP",
              "source_type": "gmail",
              "source_ref": "https://mail.google.com/mail/u/0/#all/example-thread-0001"
            },
            {
              "date": "2026-09-09",
              "lobbyist": "Lee Lobbyist",
              "official_name": "Alex Administrator",
              "official_title": "Zoning Administrator",
              "agency": "City Planning",
              "mode": "hearing",
              "summary": "Zoning Administrator hearing on the Example Bistro CUP",
              "source_type": "calendar",
              "source_ref": "example-event-0002"
            }
          ]
        }
      ]
    },
    {
      "name": "Sample Housing Partners LP",
      "address": "400 Example Way, Los Angeles, CA 90000",
      "phone": "213-555-0103",
      "payments_total": null,
      "matters": [
        {
          "description": "Site plan review for Sample Apartments, 500 Sample Court (DIR-2026-0002-SPR)",
          "agencies": ["City Planning", "Bureau of Engineering"],
          "contacts": [
            {
              "date": "2026-08-20",
              "lobbyist": "Jordan Sample",
              "official_name": "Riley Reviewer",
              "official_title": "Planning Associate",
              "agency": "City Planning",
              "mode": "call",
              "summary": "Call with Riley Reviewer about the Sample Apartments site plan review",
              "source_type": "calendar",
              "source_ref": "example-event-0003"
            },
            {
              "date": "2026-09-02",
              "lobbyist": "Jordan Sample",
              "official_name": "Casey Engineer",
              "official_title": "Civil Engineer",
              "agency": "Bureau of Engineering",
              "mode": "call",
              "summary": "Call with Casey Engineer about Sample Apartments, as reported by the user",
              "source_type": "manual",
              "source_ref": "user-reported"
            }
          ]
        }
      ]
    }
  ],
  "other_disclosures": {
    "activity_expenses": { "status": "none" },
    "lobbying_expenses": { "status": "reported", "details": "Total $31,000." },
    "contributions": { "status": "none" },
    "fundraising": { "status": "none" },
    "behested_contributions": { "status": "none" },
    "behested_donations": { "status": "none" },
    "campaign_services": { "status": "none" },
    "city_contracts": { "status": "none" }
  },
  "excluded": [
    {
      "date": "2026-07-22",
      "summary": "Emailed a county health inspector about the Example Bistro health permit",
      "reason": "Non-City agency: LA County",
      "source_ref": "https://mail.google.com/mail/u/0/#all/example-thread-0002"
    },
    {
      "date": "2026-08-12",
      "summary": "Asked City Planning by email whether a rooftop patio needs its own permit",
      "reason": "Interpretation request: advice only",
      "source_ref": "https://mail.google.com/mail/u/0/#all/example-thread-0003"
    }
  ],
  "open_items": [
    { "text": "Sample Housing Partners LP: total payments for 2026 Q3 are unknown (needed for C3 and C4)." },
    { "text": "Aug 27 meeting of the Example Neighborhood Council about Sample Apartments: not recorded. Confirm whether to report it as lobbying." }
  ]
}
```

What to notice:

- The second client has `payments_total: null` and a matching open item that names the client.
- The second open item is a gray-area item the user has not answered yet. It is not in `contacts` or `excluded`.
- Each matter's `agencies` covers the agency of every City contact under it.
- Every contact and excluded item has a one-line `summary` and a `source_ref`.
- `other_disclosures` has all eight keys. `lobbying_expenses` is `reported` with its total in `details`. The other seven are `none` because the user answered "no".

## 4. Guidance

### Matter description

Format: `<permit or entitlement> for <project>, <address> (<case no.>)`

Good:

- Conditional use permit for Example Bistro on-site alcohol, 300 Sample Boulevard (ZA-2026-0001-CUB)
- Site plan review for Sample Apartments, 500 Sample Court (DIR-2026-0002-SPR)

Bad:

- "Example Bistro": no permit, address or case number.
- "CUP": no project.
- "Zoning work for the restaurant": too vague to tell matters apart.

Take the case number from the City's own emails or the calendar entry. If there is none yet, write "(case no. not yet assigned)". Never invent one. Reuse a matter's description word for word every quarter, so the matters line up.

### Contact summaries

One line, 1 to 200 characters, in your own words. Say only what the calendar title, attendees, email subject or snippet show. If the purpose isn't visible, keep it neutral, for example "Call with Morgan Planner about the Example Bistro CUP".

Good:

- Meeting with Morgan Planner about the Example Bistro CUP
- Call with Riley Reviewer about the Sample Apartments site plan review
- Zoning Administrator hearing on the Example Bistro CUP

Bad:

- "Meeting": says nothing about the subject.
- "Hi Morgan, thanks for your time on Tuesday. As we discussed, the client would like to...": copied email text, and too long. Never paste a body or a quote.
- A summary with a line break: rejected, it must be one line.
- Private client details the report does not need, such as a client's finances.

Excluded items use the same rule for their `summary`.

### `source_ref`

- Calendar item: the event ID exactly as the Calendar connector gives it. `source_type` is `calendar`.
- Gmail thread: the thread link `https://mail.google.com/mail/u/0/#all/<threadId>`, built from the thread ID in the search result. `source_type` is `gmail`.
- Something the user told you that is in neither: `source_type` is `manual` and `source_ref` is a short note such as `user-reported`.

The website turns only https links into clickable links; other refs show as plain text.

### Excluded `reason`

Use the reason label from the Exclude table in `references/mlo-rules.md`, optionally followed by a few words of detail. Never leave it blank.

- `Non-City agency: LA County`
- `Interpretation request: advice only`
- `Internal or vendor meeting: no City official`
- `Ministerial action: fee payment`
- `Map or plot-plan preparation`

For an item the user decided is not lobbying: `Not lobbying (user's call): <a few words why>`.

### `open_items` wording

One gap per item, in plain sentences. Start with the client or the item, say what is missing, and say what is needed. Group several items of the same kind into one open item, except unknown payments, which get one item per client.

- Sample Housing Partners LP: total payments for 2026 Q3 are unknown (needed for C3 and C4).
- Example Bistro Group LLC: payments of $200 are under the $250 quarterly registration threshold. Confirm the client belongs in the report.
- Aug 27 meeting of the Example Neighborhood Council about Sample Apartments: not recorded. Confirm whether to report it as lobbying.
- Other disclosures (C5, C6 and C8 to C13): not confirmed for 2026 Q3.
- Lobbying expenses (C7): total for 2026 Q3 not provided.
- Sample Lofts LLC: no City contact found in 2026 Q3. Confirm whether to keep this client and its matter.
