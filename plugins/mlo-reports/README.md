# LA Lobbying Reports (`mlo-reports`)

A Claude plugin that drafts the LA City Lobbying Firm Quarterly Report (Form 34) under the Municipal Lobbying Ordinance. The `prepare-quarterly-report` skill scans your Google Calendar and Gmail for the quarter, sorts what it finds into lobbying contacts, exclusions and questions, asks you about the gray areas in one batch, and saves the result as a draft report through the plugin's `mlo-reports` connector, signed in as you (the `get_report` and `save_report` tools). You review and approve the draft on the website. It is a draft aid, not legal advice.

## Install

See the [marketplace README](../../README.md) to install this plugin in Claude or Claude Code, or to build a zip for upload.

## Connect

The plugin's `mlo-reports` connector points at `https://app.aandclabs.com/api/mcp`. Click **Connect**, sign in with your approved Google account, and choose **Allow** on the "Connect to LA Lobbying Reports" page. Claude then reads and saves only your own reports. Drafts appear on the website under your account, where you review, approve and file them.

To disconnect, remove the connector in Claude. If claude.ai won't connect it from the plugin, add it by hand under **Customize → Connectors → Add custom connector** with the same URL; connecting signs you in the same way.
