#!/bin/sh
# Builds dist/mlo-reports.zip for claude.ai's "Upload plugin", the fallback to adding this marketplace.
# Run from the repository root. The zip holds only public files: the connector URL has no secret in it.
set -eu
cd "$(dirname "$0")/.."
rm -f dist/mlo-reports.zip
mkdir -p dist
# Zipping from inside the plugin folder puts .claude-plugin/ at the root of the archive.
(cd plugins/mlo-reports && zip -r -X ../../dist/mlo-reports.zip . -x '*.DS_Store')
echo "Wrote dist/mlo-reports.zip."
