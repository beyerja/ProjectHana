#!/usr/bin/env bash
# test-lib.sh — shared harness for the bot-script tests.
#
# Sourced (never executed) by scripts/test-gh-review-bot.sh and scripts/test-secret-scan-hook.sh.
# Provides a temp-dir root with cleanup trap plus pass/fail counters and ok()/ko() reporters.
#
# Contract for sourcing scripts:
#   * source this file early (it sets `set -euo pipefail`);
#   * use ${TMPROOT} as the parent for any per-test temp dirs (auto-removed on exit);
#   * call ok "<msg>" / ko "<msg>" to record results;
#   * at the end, `printf 'Result: %d passed, %d failed.\n' "${pass}" "${fail}"` and
#     `[[ ${fail} -eq 0 ]]` for the exit status.

set -euo pipefail

# Throwaway root for all temp artifacts; removed when the sourcing script exits.
TMPROOT="$(mktemp -d)"
trap 'rm -rf "${TMPROOT}"' EXIT

pass=0
fail=0

ok() {
    pass=$((pass + 1))
    printf 'PASS: %s\n' "$1"
}

ko() {
    fail=$((fail + 1))
    printf 'FAIL: %s\n' "$1" >&2
}
