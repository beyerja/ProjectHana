#!/usr/bin/env bash
# extract-changelog-section.sh — print the BODY of a CHANGELOG.md version section to stdout.
#
# Usage: extract-changelog-section.sh [X.Y.Z] [--changelog <path>] [--project-yml <path>]
#
# The version under extraction is $1 when given, otherwise it is derived from the single
# `MARKETING_VERSION: "X.Y.Z"` line in project.yml (mirroring scripts/check-changelog.sh /
# scripts/bump-version.py: exactly one match required). Prints the content of the
# Keep-a-Changelog `## [X.Y.Z]` section — heading line EXCLUDED, everything up to (not
# including) the next `## [` heading or EOF. Consumed by release.yml (story 004) to build
# the GitHub Release body from the CHANGELOG.
#
# Every failure — including a missing section or an empty/whitespace-only section body —
# prints a one-line message to stderr and exits non-zero.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
    printf 'extract-changelog-section: ERROR: %s\n' "$1" >&2
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

# The section starts at the Keep-a-Changelog heading `## [X.Y.Z]` (fixed-string match on the
# exact bracketed version, anchored to a `## [` heading — `## [Unreleased]` never matches a
# semver version) and its body runs up to the next `## [` heading or EOF, heading excluded.
if ! grep -Eq "^## \[${version//./\\.}\]" "${changelog}"; then
    fail "no '## [${version}]' section in ${changelog} (version ${source_desc})"
fi

body="$(awk -v heading="## [${version}]" '
    in_section && /^## \[/ { exit }
    in_section { print }
    !in_section && index($0, heading) == 1 { in_section = 1 }
' "${changelog}")"

# Reject an empty or whitespace-only body: a Release created from it would carry a blank
# CHANGELOG block, which the workflow must treat as a broken changelog, not a silent pass.
if ! printf '%s' "${body}" | grep -q '[^[:space:]]'; then
    fail "section '## [${version}]' in ${changelog} has an empty body (version ${source_desc})"
fi

printf '%s\n' "${body}"
