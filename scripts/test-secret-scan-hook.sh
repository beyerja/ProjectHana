#!/usr/bin/env bash
# test-secret-scan-hook.sh — tests for scripts/hooks/pre-commit-secret-scan.sh.
#
# Runs in an isolated throwaway git repo so it never touches the real index. Verifies:
#   (a) the hook REJECTS a planted fake token (classic ghp_ + fine-grained github_pat_) staged content;
#   (b) the hook does NOT trigger on ordinary staged content.
#
# The planted token values are CONSTRUCTED AT RUNTIME from fragments so no real-token-shaped literal
# is ever stored in this committed file (which would otherwise be flagged by the hook itself).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="${SCRIPT_DIR}/hooks/pre-commit-secret-scan.sh"

# Shared harness: TMPROOT (+cleanup trap), pass/fail counters (pass/fail), ok()/ko().
# pass/fail/TMPROOT are assigned in the sourced lib (shellcheck cannot follow `source` without -x).
# shellcheck source=scripts/test-lib.sh disable=SC1091
source "${SCRIPT_DIR}/test-lib.sh"

# Build planted token strings of the exact shapes the hook matches, assembled from pieces so this
# source file contains no contiguous real-token-shaped literal.
classic_token() {
    printf 'ghp_%s' "$(printf 'A%.0s' {1..36})"
}
fine_grained_token() {
    printf 'github_pat_%s_%s' "$(printf '1%.0s' {1..22})" "$(printf 'B%.0s' {1..59})"
}

# Initialise an isolated repo with one committed file, returning its path.
new_repo() {
    local dir
    dir="$(mktemp -d "${TMPROOT}/repoXXXXXX")"
    git -C "${dir}" init -q
    git -C "${dir}" config user.email test@example.com
    git -C "${dir}" config user.name "Test"
    git -C "${dir}" config commit.gpgsign false
    printf 'initial\n' > "${dir}/base.txt"
    git -C "${dir}" add base.txt
    git -C "${dir}" commit -q -m "base"
    printf '%s' "${dir}"
}

# Run the hook with CWD inside the given repo; echo the exit code.
run_hook() {
    local dir="$1" rc
    set +e
    (cd "${dir}" && "${HOOK}" >/dev/null 2>&1)
    rc=$?
    set -e
    printf '%s' "${rc}"
}

# --- (a) rejects a planted classic token ----------------------------------------------------------
test_rejects_classic() {
    local dir rc
    dir="$(new_repo)"
    printf 'token = "%s"\n' "$(classic_token)" > "${dir}/leak.txt"
    git -C "${dir}" add leak.txt
    rc="$(run_hook "${dir}")"
    if [[ "${rc}" -ne 0 ]]; then
        ok "rejects planted classic ghp_ token (exit ${rc})"
    else
        ko "should reject planted classic token, exited 0"
    fi
}

# --- (a) rejects a planted fine-grained token -----------------------------------------------------
test_rejects_fine_grained() {
    local dir rc
    dir="$(new_repo)"
    printf 'token = "%s"\n' "$(fine_grained_token)" > "${dir}/leak.txt"
    git -C "${dir}" add leak.txt
    rc="$(run_hook "${dir}")"
    if [[ "${rc}" -ne 0 ]]; then
        ok "rejects planted fine-grained github_pat_ token (exit ${rc})"
    else
        ko "should reject planted fine-grained token, exited 0"
    fi
}

# --- (b) does NOT trigger on ordinary content -----------------------------------------------------
test_allows_ordinary() {
    local dir rc
    dir="$(new_repo)"
    {
        printf 'func greet() { print("hello world") }\n'
        printf '# ghp_ and github_pat_ are mentioned but not real tokens here.\n'
        printf 'let id = "ghp_FAKE0000000000000000000000000000000000"\n'
    } > "${dir}/ordinary.swift"
    git -C "${dir}" add ordinary.swift
    rc="$(run_hook "${dir}")"
    if [[ "${rc}" -eq 0 ]]; then
        ok "ordinary content passes (incl. clearly-fake ghp_FAKE literal)"
    else
        ko "ordinary content should pass, exited ${rc}"
    fi
}

# --- (c) rejects a line carrying BOTH a real-shaped token AND a FAKE sentinel ----------------------
# Regression for the line-level allowlist bypass: a single line with a real-shaped ghp_ token next to
# a ghp_FAKE… sentinel must still be REJECTED (the FAKE must not whitelist the whole line).
test_rejects_mixed_real_and_fake() {
    local dir rc
    dir="$(new_repo)"
    {
        printf 'real = "%s"  # decoy ghp_FAKE0000000000000000000000000000000000\n' "$(classic_token)"
    } > "${dir}/mixed.txt"
    git -C "${dir}" add mixed.txt
    rc="$(run_hook "${dir}")"
    if [[ "${rc}" -ne 0 ]]; then
        ok "rejects mixed real+FAKE line (exit ${rc})"
    else
        ko "mixed real+FAKE line should be rejected, exited 0 (line-level allowlist bypass)"
    fi
}

echo "== test-secret-scan-hook.sh =="
test_rejects_classic
test_rejects_fine_grained
test_rejects_mixed_real_and_fake
test_allows_ordinary

echo
# shellcheck disable=SC2154  # pass/fail are set in the sourced test-lib.sh
printf 'Result: %d passed, %d failed.\n' "${pass}" "${fail}"
# shellcheck disable=SC2154
[[ ${fail} -eq 0 ]]
