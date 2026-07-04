#!/usr/bin/env bash
# test-bump-version.sh — tests for scripts/bump-version.py.
#
# Exercises the bump script against throwaway fixture copies via
# `--file <tmp>/project.yml --no-generate`, so no xcodegen/direnv run and no repo mutation is
# ever needed. Mirrors the structure of scripts/test-gh-review-bot.sh (shared harness in
# scripts/test-lib.sh) and is wired into `just test-version-scripts`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUMP="${SCRIPT_DIR}/bump-version.py"
REPO_YML="${SCRIPT_DIR}/../project.yml"

# Shared harness: TMPROOT (+cleanup trap), pass/fail counters (pass/fail), ok()/ko().
# shellcheck source=scripts/test-lib.sh disable=SC1091
source "${SCRIPT_DIR}/test-lib.sh"

# make_fixture <marketing> <build|-> — write a small project.yml-shaped fixture and print its
# path. Pass "-" as <build> to omit the CURRENT_PROJECT_VERSION line (missing-key case).
make_fixture() {
    local marketing="$1" build="$2" dir file
    dir="$(mktemp -d "${TMPROOT}/bumpXXXXXX")"
    file="${dir}/project.yml"
    {
        printf '%s\n' "# fixture — comments and formatting must survive a bump byte-for-byte"
        printf '%s\n' "name: Hanahuac"
        printf '%s\n' "settings:"
        printf '%s\n' "  base:"
        printf '%s\n' "    PRODUCT_BUNDLE_IDENTIFIER: com.hanahuac.app   # untouched line"
        printf '    MARKETING_VERSION: "%s"\n' "${marketing}"
        if [[ "${build}" != "-" ]]; then
            printf '    CURRENT_PROJECT_VERSION: "%s"\n' "${build}"
        fi
        printf '%s\n' '    SWIFT_VERSION: "5.10"'
    } > "${file}"
    printf '%s' "${file}"
}

# run_bump <part> <file> — run the script with --no-generate; sets RC / OUT / ERR globals.
run_bump() {
    local part="$1" file="$2"
    set +e
    OUT="$(python3 "${BUMP}" "${part}" --file "${file}" --no-generate 2> "${TMPROOT}/last-stderr")"
    RC=$?
    set -e
    ERR="$(cat "${TMPROOT}/last-stderr")"
}

# --- happy paths: semver part bumped (lower parts reset), build +1, rest byte-identical -----------
assert_happy() {
    local part="$1" from_v="$2" from_b="$3" to_v="$4" to_b="$5" file expected
    file="$(make_fixture "${from_v}" "${from_b}")"
    expected="$(make_fixture "${to_v}" "${to_b}")"
    run_bump "${part}" "${file}"

    if [[ ${RC} -eq 0 ]]; then
        ok "${part} ${from_v}/${from_b} -> exit 0"
    else
        ko "${part} ${from_v}/${from_b} exited ${RC}: ${ERR}"
    fi
    # Fixtures differ ONLY in the two version values, so a byte-compare against the expected
    # fixture proves both the new values AND that every other byte survived unchanged.
    if cmp -s "${file}" "${expected}"; then
        ok "${part} -> ${to_v}/${to_b}; rest of the file byte-identical"
    else
        ko "${part} produced wrong file content (wanted ${to_v}/${to_b})"
    fi
    if [[ "${OUT}" == *"${from_v} -> ${to_v}"* && "${OUT}" == *"${from_b} -> ${to_b}"* ]]; then
        ok "${part} -> prints old -> new for both fields"
    else
        ko "${part} stdout missing old -> new values: ${OUT}"
    fi
}

test_happy_paths() {
    assert_happy patch 1.0.0 1 1.0.1 2
    assert_happy minor 1.0.1 2 1.1.0 3   # patch resets
    assert_happy major 1.1.0 3 2.0.0 4   # minor + patch reset
}

# --- error paths: non-zero exit, message on stderr, fixture left unmodified -----------------------
# assert_fails <label> <fixture-file> [script-args…]
assert_fails() {
    local label="$1" file="$2" pristine rc
    shift 2
    pristine="$(mktemp "${TMPROOT}/pristineXXXXXX")"
    cp "${file}" "${pristine}"
    set +e
    python3 "${BUMP}" "$@" --file "${file}" --no-generate > /dev/null 2> "${TMPROOT}/last-stderr"
    rc=$?
    set -e

    if [[ ${rc} -ne 0 ]]; then
        ok "${label} -> non-zero exit (${rc})"
    else
        ko "${label} should exit non-zero, got 0"
    fi
    if [[ -s "${TMPROOT}/last-stderr" ]]; then
        ok "${label} -> message on stderr"
    else
        ko "${label} printed nothing to stderr"
    fi
    if cmp -s "${file}" "${pristine}"; then
        ok "${label} -> fixture left unmodified"
    else
        ko "${label} modified the fixture despite failing"
    fi
}

test_error_paths() {
    assert_fails "invalid part arg (bogus)" "$(make_fixture 1.0.0 1)" bogus
    assert_fails "missing part arg" "$(make_fixture 1.0.0 1)"
    assert_fails "non-semver current value (1.0)" "$(make_fixture 1.0 1)" patch
    assert_fails "non-integer build number" "$(make_fixture 1.0.0 seven)" patch
    assert_fails "missing CURRENT_PROJECT_VERSION key" "$(make_fixture 1.0.0 -)" patch
}

# --- the pre-normalization value must be rejected with a pointer at story 001 task 001 ------------
test_pre_normalization_hint() {
    local file
    file="$(make_fixture 1.0 1)"
    run_bump patch "${file}"
    if [[ ${RC} -ne 0 && "${ERR}" == *"001"* ]]; then
        ok "non-semver 1.0 -> error points at the normalization task (001)"
    else
        ko "non-semver 1.0 error missing task-001 pointer: ${ERR}"
    fi
}

# --- against a copy of the REAL project.yml: exactly the two version lines change ------------------
test_real_project_yml() {
    local file diffout
    file="${TMPROOT}/real-project.yml"
    cp "${REPO_YML}" "${file}"
    run_bump patch "${file}"
    if [[ ${RC} -eq 0 ]]; then
        ok "real project.yml copy -> exit 0"
    else
        ko "real project.yml copy exited ${RC}: ${ERR}"
    fi
    diffout="${TMPROOT}/real.diff"
    diff "${REPO_YML}" "${file}" > "${diffout}" || true
    if [[ "$(grep -c '^[<>]' "${diffout}")" == "4" ]] \
        && grep -q '^> .*MARKETING_VERSION' "${diffout}" \
        && grep -q '^> .*CURRENT_PROJECT_VERSION' "${diffout}"; then
        ok "real project.yml copy -> only the two version lines change"
    else
        ko "real project.yml copy -> unexpected diff shape"
    fi
}

echo "== test-bump-version.sh =="
test_happy_paths
test_error_paths
test_pre_normalization_hint
test_real_project_yml

echo
# shellcheck disable=SC2154  # pass/fail are set in the sourced test-lib.sh
printf 'Result: %d passed, %d failed.\n' "${pass}" "${fail}"
# shellcheck disable=SC2154
[[ ${fail} -eq 0 ]]
