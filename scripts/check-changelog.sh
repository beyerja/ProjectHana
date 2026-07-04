#!/usr/bin/env bash
# check-changelog.sh — verify CHANGELOG.md has a section for the version under check.
#
# Usage: check-changelog.sh [X.Y.Z] [--changelog <path>] [--project-yml <path>]
#
# The version under check is $1 when given, otherwise it is derived from the single
# `MARKETING_VERSION: "X.Y.Z"` line in project.yml (mirroring scripts/bump-version.py:
# exactly one match required). The check passes iff the changelog contains a
# Keep-a-Changelog version heading `## [X.Y.Z]` for that version; `## [Unreleased]`
# never satisfies it. Consumed by `just check-changelog`, `just release-check`
# (story 003) and release.yml (story 004).
#
# Every failure prints a one-line message to stderr and exits non-zero.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
    printf 'check-changelog: ERROR: %s\n' "$1" >&2
    exit 1
}

changelog="${SCRIPT_DIR}/../CHANGELOG.md"
project_yml="${SCRIPT_DIR}/../project.yml"
version=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --changelog)
            [[ $# -ge 2 ]] || fail "--changelog requires a path argument"
            changelog="$2"
            shift 2
            ;;
        --project-yml)
            [[ $# -ge 2 ]] || fail "--project-yml requires a path argument"
            project_yml="$2"
            shift 2
            ;;
        -*)
            fail "unknown option: $1"
            ;;
        *)
            [[ -z "${version}" ]] || fail "unexpected extra argument: $1"
            version="$1"
            shift
            ;;
    esac
done

# read_marketing_version <project.yml> — print the MARKETING_VERSION value; mirrors
# bump-version.py semantics (exactly ONE quoted `MARKETING_VERSION: "…"` line).
read_marketing_version() {
    local file="$1" matches count
    [[ -f "${file}" ]] || fail "project.yml not found: ${file}"
    matches="$(grep -E '^[[:space:]]*MARKETING_VERSION:[[:space:]]*"[^"]*"' "${file}" || true)"
    count="$(printf '%s' "${matches}" | grep -c . || true)"
    if [[ "${count}" -eq 0 ]]; then
        fail "no MARKETING_VERSION: \"…\" line found in ${file}"
    elif [[ "${count}" -gt 1 ]]; then
        fail "MARKETING_VERSION matched ${count} lines in ${file}; expected exactly one"
    fi
    printf '%s' "${matches}" | sed -E 's/^[[:space:]]*MARKETING_VERSION:[[:space:]]*"([^"]*)".*/\1/'
}

if [[ -z "${version}" ]]; then
    version="$(read_marketing_version "${project_yml}")"
    source_desc="derived from ${project_yml}"
else
    source_desc="explicit argument"
fi

semver_re='^[0-9]+\.[0-9]+\.[0-9]+$'
if [[ ! "${version}" =~ ${semver_re} ]]; then
    fail "version '${version}' (${source_desc}) is not strict semver X.Y.Z"
fi

[[ -f "${changelog}" ]] || fail "changelog not found: ${changelog}"

# Keep-a-Changelog version heading, e.g. `## [1.0.0] - 2026-07-04`. Fixed-string body
# match on the exact bracketed version, anchored to a `## [` heading.
if ! grep -Eq "^## \[${version//./\\.}\]" "${changelog}"; then
    fail "no '## [${version}]' section in ${changelog} (version ${source_desc}); add one before releasing"
fi

printf 'check-changelog: OK — %s has a section for version %s (%s).\n' \
    "${changelog}" "${version}" "${source_desc}"
