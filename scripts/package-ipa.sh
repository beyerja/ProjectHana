#!/usr/bin/env bash
# Package an UNSIGNED .ipa from a Release .xcarchive (story 003, proven empirically).
#
# An .ipa is just a zip whose root contains Payload/<App>.app. No signing step is involved —
# this produces an installable-evidence artifact only (sideload / re-sign later); the signed
# device archive path activates once an Apple Developer account exists.
#
# `ditto --norsrc` matters: without it ditto embeds AppleDouble `._*` metadata files (and
# `--sequesterRsrc` adds a `__MACOSX/` tree) into the zip. With it, `unzip -l` shows a clean
# `Payload/Hanahuac.app/...` layout.
#
# Usage: package-ipa.sh <path/to/.xcarchive> <path/to/output.ipa>
set -euo pipefail

usage="usage: package-ipa.sh <path/to/.xcarchive> <path/to/output.ipa>"
ARCHIVE="${1:?${usage}}"
IPA="${2:?${usage}}"

APP="${ARCHIVE}/Products/Applications/Hanahuac.app"
if [[ ! -d "${APP}" ]]; then
    echo "FAIL: no Hanahuac.app at ${APP}" >&2
    exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT

mkdir -p "${STAGE}/Payload"
ditto "${APP}" "${STAGE}/Payload/Hanahuac.app"
rm -f "${IPA}"
mkdir -p "$(dirname "${IPA}")"
ditto -c -k --norsrc --keepParent "${STAGE}/Payload" "${IPA}"

echo "Packaged unsigned ipa: ${IPA}"
