#!/usr/bin/env bash
# gh-review-bot.sh — the single sanctioned path to authenticate as the Hanahuac-Bot identity.
#
# Reads the bot's fine-grained PAT from the macOS Keychain (service `hana-review-bot`) and execs the
# command passed as arguments with GH_TOKEN set in the CHILD process's environment only. The token is
# never printed, never written to a file, and never visible in this script's own output.
#
# Usage:
#   scripts/gh-review-bot.sh gh api user
#   scripts/gh-review-bot.sh gh pr review 123 --approve
#
# Setup (one-time, human): see docs/bot-credentials.md.
#
# Credential-safety invariants (do not weaken):
#   - xtrace (`set -x`) is NEVER enabled — it would echo the token-bearing exec line.
#   - The token value is NEVER echo/printf'd, redirected, or written to any file.
#   - On an absent Keychain item the underlying command is NOT run (fail closed).
set -euo pipefail

readonly KEYCHAIN_SERVICE="hana-review-bot"
readonly SETUP_DOCS="docs/bot-credentials.md"

# Guard: nothing to exec.
if [[ $# -eq 0 ]]; then
    echo "usage: $0 <command> [args...]   (e.g. $0 gh api user)" >&2
    echo "Wraps the command with GH_TOKEN read from Keychain service '${KEYCHAIN_SERVICE}'." >&2
    exit 2
fi

# Read the token from the Keychain. `-w` prints only the password to stdout; we capture it into a
# local variable and never re-emit it. A missing item makes `security` exit non-zero.
token=""
if ! token="$(security find-generic-password -s "${KEYCHAIN_SERVICE}" -w 2>/dev/null)"; then
    token=""
fi

if [[ -z "${token}" ]]; then
    {
        echo "error: no bot token found in the macOS Keychain (service '${KEYCHAIN_SERVICE}')."
        echo "The underlying command was NOT run."
        echo "Add the Hanahuac-Bot token, then retry. Setup instructions: ${SETUP_DOCS}"
        echo "  security add-generic-password -s ${KEYCHAIN_SERVICE} -a <account> -w"
    } >&2
    exit 1
fi

# Export GH_TOKEN into the child only and hand off. `exec` replaces this shell so the token-bearing
# environment never lingers. Arguments are passed through unchanged.
exec env GH_TOKEN="${token}" "$@"
