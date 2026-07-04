#!/usr/bin/env bash
# test-check-changelog.sh — tests for scripts/check-changelog.sh.
#
# Fixture-only: exercises the check against printf-built throwaway changelog/project.yml
# copies in ${TMPROOT} via `--changelog`/`--project-yml`, so no repo file is ever read or
# mutated (no ordering coupling with the version-bump flow). Mirrors the structure of
# scripts/test-bump-version.sh (shared harness in scripts/test-lib.sh) and is wired into
# `just test-release-scripts`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="${SCRIPT_DIR}/check-changelog.sh"

# Shared harness: TMPROOT (+cleanup trap), pass/fail counters (pass/fail), ok()/ko().
# shellcheck source=scripts/test-lib.sh disable=SC1091
source "${SCRIPT_DIR}/test-lib.sh"

# make_changelog <version|-> — write a Keep-a-Changelog-shaped fixture and print its path.
# Pass "-" to produce an [Unreleased]-only changelog with no released version section.
make_changelog() {
    local version="$1" dir file
    dir="$(mktemp -d "${TMPROOT}/chlogXXXXXX")"
    file="${dir}/CHANGELOG.md"
    {
        printf '%s\n' "# Changelog"
        printf '%s\n' ""
        printf '%s\n' "## [Unreleased]"
        printf '%s\n' ""
        printf '%s\n' "- pending work"
        if [[ "${version}" != "-" ]]; then
            printf '%s\n' ""
            printf '## [%s] - 2026-07-04\n' "${version}"
            printf '%s\n' ""
            printf '%s\n' "- released work"
        fi
    } > "${file}"
    printf '%s' "${file}"
}

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
        ok "${label} -> prints confirmation"
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
    local chlog pyml
    chlog="$(make_changelog 1.0.0)"
    assert_pass "explicit version present" 1.0.0 --changelog "${chlog}"

    pyml="$(make_project_yml 1.0.0)"
    assert_pass "version derived from project.yml" \
        --changelog "${chlog}" --project-yml "${pyml}"

    chlog="$(make_changelog 2.11.30)"
    assert_pass "multi-digit version present" 2.11.30 --changelog "${chlog}"
}

test_negative_paths() {
    local chlog pyml
    chlog="$(make_changelog 1.0.0)"
    assert_fails "version absent from changelog" 1.0.1 --changelog "${chlog}"

    chlog="$(make_changelog -)"
    assert_fails "[Unreleased]-only changelog never satisfies" 1.0.0 --changelog "${chlog}"

    assert_fails "missing changelog file" 1.0.0 --changelog "${TMPROOT}/nope/CHANGELOG.md"

    chlog="$(make_changelog 1.0.0)"
    assert_fails "bogus version argument" bogus --changelog "${chlog}"
    assert_fails "two-component version argument" 1.0 --changelog "${chlog}"

    pyml="$(make_project_yml -)"
    assert_fails "project.yml without MARKETING_VERSION" \
        --changelog "${chlog}" --project-yml "${pyml}"
}

echo "== test-check-changelog.sh =="
test_positive_paths
test_negative_paths

echo
# shellcheck disable=SC2154  # pass/fail are set in the sourced test-lib.sh
printf 'Result: %d passed, %d failed.\n' "${pass}" "${fail}"
# shellcheck disable=SC2154
[[ ${fail} -eq 0 ]]
