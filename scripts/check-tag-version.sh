#!/usr/bin/env bash
# check-tag-version.sh — verify a release tag matches MARKETING_VERSION in project.yml.
#
# Usage: check-tag-version.sh <tag> [--project-yml <path>]
#
# The tag must be `v` + strict semver, with an optional semver prerelease suffix:
# `vX.Y.Z` or `vX.Y.Z-<prerelease>` (e.g. v1.1.0-rc.1). Its X.Y.Z base must equal the
# single `MARKETING_VERSION: "X.Y.Z"` value in project.yml (mirroring
# scripts/bump-version.py: exactly one match required). Consumed by
# `just check-tag-version`, `just release-check` (story 003) and release.yml (story 004).
#
# Every failure prints a one-line message to stderr and exits non-zero.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() {
    printf 'check-tag-version: ERROR: %s\n' "$1" >&2
    exit 1
}

project_yml="${SCRIPT_DIR}/../project.yml"
tag=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-yml)
            [[ $# -ge 2 ]] || fail "--project-yml requires a path argument"
            project_yml="$2"
            shift 2
            ;;
        -*)
            fail "unknown option: $1"
            ;;
        *)
            [[ -z "${tag}" ]] || fail "unexpected extra argument: $1"
            tag="$1"
            shift
            ;;
    esac
done

[[ -n "${tag}" ]] || fail "missing tag argument (usage: check-tag-version.sh vX.Y.Z[-prerelease])"

[[ "${tag}" == v* ]] || fail "tag '${tag}' must start with a 'v' prefix (e.g. v1.0.0)"

# v + strict numeric X.Y.Z base + optional semver prerelease: dot-separated, non-empty
# alphanumeric/hyphen identifiers (e.g. -rc.1, -beta). Empty identifiers (v1.0.0-, v1.0.0-rc..1)
# and anything after them are rejected.
tag_re='^v([0-9]+\.[0-9]+\.[0-9]+)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'
if [[ ! "${tag}" =~ ${tag_re} ]]; then
    fail "tag '${tag}' is not vX.Y.Z with an optional semver prerelease suffix (e.g. v1.1.0-rc.1)"
fi
base="${BASH_REMATCH[1]}"

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

marketing="$(read_marketing_version "${project_yml}")"

if [[ "${base}" != "${marketing}" ]]; then
    fail "tag '${tag}' base ${base} != MARKETING_VERSION ${marketing} in ${project_yml}"
fi

printf 'check-tag-version: OK — tag %s matches MARKETING_VERSION %s.\n' "${tag}" "${marketing}"
