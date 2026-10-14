# A&C Labs plugin marketplace

This marketplace has one plugin, **LA Lobbying Reports** (`mlo-reports`). It drafts the LA City Lobbying Firm Quarterly Report (Form 34) under the Municipal Lobbying Ordinance from your Google Calendar and Gmail, and saves the draft to [app.aandclabs.com](https://app.aandclabs.com) for you to review, approve and file. It is a draft aid, not legal advice.

## Before you start

- **An approved account.** Access is by invitation for now. Ask A&C Labs to add the Google account you'll sign in with.
- **Gmail and Google Calendar connected in Claude.** The skill reads them to find lobbying contacts.

## Install in Claude (claude.ai, desktop and Cowork)

1. Open **Customize → Plugins → Add → Add marketplace** and enter `aandclabs/mlo-reports-marketplace`.
2. Find **LA Lobbying Reports** in the marketplace and install it.
3. Open the plugin's **Connectors** tab and click **Connect** on `mlo-reports`.
4. Sign in with your approved Google account. On the "Connect to LA Lobbying Reports" page, check that it says Claude and returns to claude.ai, then choose **Allow**.

Then ask Claude to prepare your lobbying report for last quarter.

## Install in Claude Code

```sh
claude plugin marketplace add aandclabs/mlo-reports-marketplace
claude plugin install mlo-reports@mlo-reports-marketplace
```

Adding the marketplace only makes the plugin available; installing it is a separate step. The connector asks you to sign in the first time Claude uses it.

## Without the marketplace

Build a zip and upload it under **Customize → Plugins → Add → Upload plugin**:

```sh
./scripts/build-zip.sh
```

The zip contains no secret. The connector URL, `https://app.aandclabs.com/api/mcp`, is public; each person signs in with their own account and sees only their own reports.

## What the plugin can and can't do

The connector has two tools: `get_report` reads your reports and `save_report` saves a draft. It can't approve or file a report; only you can, on the website. If your account isn't approved, sign-in stops at "access denied" and the connector can't read anything.

## For maintainers

To release a change, edit the plugin under `plugins/mlo-reports/`, then raise `version` to the same value in both `plugins/mlo-reports/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Check both manifests with:

```sh
claude plugin validate --strict .
claude plugin validate --strict plugins/mlo-reports
```

Push to `main`. People who added the marketplace pick up the new version when Claude refreshes it.

The service behind the connector (the website, the `/api/mcp` endpoint and the database) lives in a separate, private repository.
