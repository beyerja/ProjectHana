#!/usr/bin/env bash
# test-extract-changelog-section.sh — tests for scripts/extract-changelog-section.sh.
#
# Fixture-only: exercises the extractor against printf-built throwaway changelog/project.yml
# copies in ${TMPROOT} via `--changelog`/`--project-yml`, so no repo file is ever read or
# mutated. Mirrors the structure of scripts/test-check-changelog.sh (shared harness in
# scripts/test-lib.sh) and is wired into `just test-release-scripts`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACT="${SCRIPT_DIR}/extract-changelog-section.sh"

# Shared harness: TMPROOT (+cleanup trap), pass/fail counters (pass/fail), ok()/ko().
# shellcheck source=scripts/test-lib.sh disable=SC1091
source "${SCRIPT_DIR}/test-lib.sh"

# make_changelog_midfile <version> — fixture where the version section sits BETWEEN
# [Unreleased] and an older release, so extraction must stop at the next `## [` heading.
make_changelog_midfile() {
    local version="$1" dir file
    dir="$(mktemp -d "${TMPROOT}/chlogXXXXXX")"
    file="${dir}/CHANGELOG.md"
    {
        printf '%s\n' "# Changelog"
        printf '%s\n' ""
        printf '%s\n' "## [Unreleased]"
        printf '%s\n' ""
        printf '%s\n' "- pending work"
        printf '%s\n' ""
        printf '## [%s] - 2026-07-05\n' "${version}"
        printf '%s\n' ""
        printf '%s\n' "### Added"
        printf '%s\n' ""
        printf '%s\n' "- released work"
        printf '%s\n' ""
        printf '%s\n' "## [0.0.1] - 2026-01-01"
        printf '%s\n' ""
        printf '%s\n' "- ancient work"
    } > "${file}"
    printf '%s' "${file}"
}

# make_changelog_eof <version> — fixture where the version section is the LAST section
# (body runs to EOF, no trailing `## [` heading).
make_changelog_eof() {
    local version="$1" dir file
    dir="$(mktemp -d "${TMPROOT}/chlogXXXXXX")"
    file="${dir}/CHANGELOG.md"
    {
        printf '%s\n' "# Changelog"
        printf '%s\n' ""
        printf '%s\n' "## [Unreleased]"
        printf '%s\n' ""
        printf '## [%s] - 2026-07-05\n' "${version}"
        printf '%s\n' ""
        printf '%s\n' "- final section work"
    } > "${file}"
    printf '%s' "${file}"
}

# make_changelog_empty_body <version> — fixture whose version section exists but whose
# body is whitespace-only (must be rejected).
make_changelog_empty_body() {
    local version="$1" dir file
    dir="$(mktemp -d "${TMPROOT}/chlogXXXXXX")"
    file="${dir}/CHANGELOG.md"
    {
        printf '%s\n' "# Changelog"
        printf '%s\n' ""
        printf '## [%s] - 2026-07-05\n' "${version}"
        printf '%s\n' ""
        printf '%s\n' ""
        printf '%s\n' "## [0.0.1] - 2026-01-01"
        printf '%s\n' ""
        printf '%s\n' "- ancient work"
    } > "${file}"
    printf '%s' "${file}"
}

# make_project_yml <marketing> — write a project.yml-shaped fixture and print its path.
make_project_yml() {
    local marketing="$1" dir file
    dir="$(mktemp -d "${TMPROOT}/pymlXXXXXX")"
    file="${dir}/project.yml"
    {
        printf '%s\n' "name: Hanahuac"
        printf '%s\n' "settings:"
        printf '%s\n' "  base:"
        printf '    MARKETING_VERSION: "%s"\n' "${marketing}"
        printf '%s\n' '    CURRENT_PROJECT_VERSION: "1"'
    } > "${file}"
    printf '%s' "${file}"
}

# run_extract [args…] — run the script; sets RC / OUT / ERR globals.
run_extract() {
    set +e
    OUT="$(bash "${EXTRACT}" "$@" 2> "${TMPROOT}/last-stderr")"
    RC=$?
    set -e
    ERR="$(cat "${TMPROOT}/last-stderr")"
}

# assert_extracts <label> <must-contain> <must-not-contain> [args…]
assert_extracts() {
    local label="$1" want="$2" forbid="$3"
    shift 3
    run_extract "$@"
    if [[ ${RC} -eq 0 ]]; then
        ok "${label} -> exit 0"
    else
        ko "${label} exited ${RC}: ${ERR}"
    fi
    if [[ "${OUT}" == *"${want}"* ]]; then
        ok "${label} -> body contains '${want}'"
    else
        ko "${label} body missing '${want}': ${OUT}"
    fi
    if [[ "${OUT}" != *"${forbid}"* ]]; then
        ok "${label} -> body excludes '${forbid}'"
    else
        ko "${label} body leaked '${forbid}': ${OUT}"
    fi
    if [[ "${OUT}" != *"## ["* ]]; then
        ok "${label} -> no section heading in body"
    else
        ko "${label} body leaked a '## [' heading: ${OUT}"
    fi
}

# assert_fails <label> [args…]
assert_fails() {
    local label="$1"
    shift
    run_extract "$@"
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
    chlog="$(make_changelog_midfile 1.0.0)"
    assert_extracts "section mid-file (stops at next heading)" \
        "released work" "ancient work" 1.0.0 --changelog "${chlog}"

    chlog="$(make_changelog_eof 2.11.30)"
    assert_extracts "section at EOF (runs to end of file)" \
        "final section work" "pending work" 2.11.30 --changelog "${chlog}"

    chlog="$(make_changelog_midfile 1.2.3)"
    pyml="$(make_project_yml 1.2.3)"
    assert_extracts "version derived from project.yml" \
        "released work" "ancient work" --changelog "${chlog}" --project-yml "${pyml}"
}

test_negative_paths() {
    local chlog pyml
    chlog="$(make_changelog_midfile 1.0.0)"
    assert_fails "missing section fails" 9.9.9 --changelog "${chlog}"

    chlog="$(make_changelog_empty_body 1.0.0)"
    assert_fails "empty/whitespace-only body fails" 1.0.0 --changelog "${chlog}"

    chlog="$(make_changelog_midfile 1.0.0)"
    assert_fails "bogus version argument" bogus --changelog "${chlog}"

    assert_fails "missing changelog file" 1.0.0 --changelog "${TMPROOT}/nope/CHANGELOG.md"

    pyml="$(mktemp -d "${TMPROOT}/pymlXXXXXX")/project.yml"
    printf '%s\n' "name: Hanahuac" > "${pyml}"
    assert_fails "project.yml without MARKETING_VERSION" \
        --changelog "${chlog}" --project-yml "${pyml}"
}

echo "== test-extract-changelog-section.sh =="
test_positive_paths
test_negative_paths

echo
# shellcheck disable=SC2154  # pass/fail are set in the sourced test-lib.sh
printf 'Result: %d passed, %d failed.\n' "${pass}" "${fail}"
# shellcheck disable=SC2154
[[ ${fail} -eq 0 ]]
