#!/usr/bin/env bash
# test-check-tag-version.sh — tests for scripts/check-tag-version.sh.
#
# Fixture-only: exercises the check against printf-built throwaway project.yml copies in
# ${TMPROOT} via `--project-yml`, so no repo file is ever read or mutated. Mirrors the
# structure of scripts/test-bump-version.sh (shared harness in scripts/test-lib.sh) and is
# wired into `just test-release-scripts`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="${SCRIPT_DIR}/check-tag-version.sh"

# Shared harness: TMPROOT (+cleanup trap), pass/fail counters (pass/fail), ok()/ko().
# shellcheck source=scripts/test-lib.sh disable=SC1091
source "${SCRIPT_DIR}/test-lib.sh"

# make_project_yml <marketing|-> — write a project.yml-shaped fixture and print its path.
# Pass "-" to omit the MARKETING_VERSION line (missing-key case).
make_project_yml() {
    local marketing="$1" dir file
    dir="$(mktemp -d "${TMPROOT}/pymlXXXXXX")"
    file="${dir}/project.yml"
    {
        printf '%s\n' "name: Hanahuac"
        printf '%s\n' "settings:"
        printf '%s\n' "  base:"
        if [[ "${marketing}" != "-" ]]; then
            printf '    MARKETING_VERSION: "%s"\n' "${marketing}"
        fi
        printf '%s\n' '    CURRENT_PROJECT_VERSION: "1"'
    } > "${file}"
    printf '%s' "${file}"
}

# run_check [args…] — run the script; sets RC / OUT / ERR globals.
run_check() {
    set +e
    OUT="$(bash "${CHECK}" "$@" 2> "${TMPROOT}/last-stderr")"
    RC=$?
    set -e
    ERR="$(cat "${TMPROOT}/last-stderr")"
}

# assert_pass <label> [args…]
assert_pass() {
    local label="$1"
    shift
    run_check "$@"
    if [[ ${RC} -eq 0 ]]; then
        ok "${label} -> exit 0"
    else
        ko "${label} exited ${RC}: ${ERR}"
    fi
    if [[ "${OUT}" == *"OK"* ]]; then
        ok "${label} -> prints matched tag/version"
    else
        ko "${label} stdout missing confirmation: ${OUT}"
    fi
}

# assert_fails <label> [args…]
assert_fails() {
    local label="$1"
    shift
    run_check "$@"
    if [[ ${RC} -ne 0 ]]; then
        ok "${label} -> non-zero exit (${RC})"
    else
        ko "${label} should exit non-zero, got 0: ${OUT}"
    fi
    if [[ -n "${ERR}" ]]; then
        ok "${label} -> message on stderr"
    else
        ko "${label} printed nothing to stderr"
    fi
}

test_positive_paths() {
    local pyml
    pyml="$(make_project_yml 1.0.0)"
    assert_pass "v1.0.0 vs MARKETING_VERSION 1.0.0" v1.0.0 --project-yml "${pyml}"

    pyml="$(make_project_yml 1.1.0)"
    assert_pass "prerelease v1.1.0-rc.1 vs 1.1.0" v1.1.0-rc.1 --project-yml "${pyml}"
}

test_negative_paths() {
    local pyml
    pyml="$(make_project_yml 1.0.0)"
    assert_fails "version mismatch (v1.0.1 vs 1.0.0)" v1.0.1 --project-yml "${pyml}"
    assert_fails "missing v prefix (1.0.0)" 1.0.0 --project-yml "${pyml}"
    assert_fails "two-component tag (v1.0)" v1.0 --project-yml "${pyml}"
    assert_fails "malformed prerelease (v1.0.0-)" v1.0.0- --project-yml "${pyml}"
    assert_fails "empty prerelease identifier (v1.0.0-rc..1)" v1.0.0-rc..1 --project-yml "${pyml}"
    assert_fails "missing tag argument" --project-yml "${pyml}"

    pyml="$(make_project_yml -)"
    assert_fails "project.yml without MARKETING_VERSION" v1.0.0 --project-yml "${pyml}"
}

echo "== test-check-tag-version.sh =="
test_positive_paths
test_negative_paths

echo
# shellcheck disable=SC2154  # pass/fail are set in the sourced test-lib.sh
printf 'Result: %d passed, %d failed.\n' "${pass}" "${fail}"
# shellcheck disable=SC2154
[[ ${fail} -eq 0 ]]
