#!/usr/bin/env bash
# Validate the zero-packs offline base-only launch path against a freshly built app bundle.
#
# Hard guarantee (asserted, fails the script):
#   - The always-bundled base languages en.lproj + es-MX.lproj ARE present in the built bundle, so
#     the app is fully usable offline from base strings alone with NO packs downloaded. This is the
#     base-only launch path the runtime relies on (BundledLanguagePackProvider + the fr/de/ko/nah
#     fallback chain to es-MX/en, with es-ES routing es-ES -> es-MX -> en).
#   - The non-base languages are declared as On-Demand Resources in the generated project
#     (knownAssetTags lang-fr/de/es-ES/ko/nah), i.e. not unconditionally part of the always-bundled
#     resource contract.
#
# Platform note (informational, NOT a failure):
#   On iOS *device* / App Store archive builds, ODR-tagged resources are split out of the main bundle
#   into Apple-hosted asset packs and are absent until downloaded. On Mac Catalyst and Simulator
#   builds Xcode always EMBEDS tagged resources into the app for local development (ODR pack splitting
#   is an iOS-device/App-Store mechanism), so their presence in such a bundle is expected and is
#   reported, not failed. The data-only + tag-contract guarantees are enforced by
#   scripts/verify-odr-packs.sh independent of build platform.
#
# Usage: verify-base-only-bundle.sh <derivedDataPath>
set -euo pipefail

DD="${1:?usage: verify-base-only-bundle.sh <derivedDataPath>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PBXPROJ="${ROOT}/Hanahuac.xcodeproj/project.pbxproj"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

APP="$(find "${DD}" -name 'Hanahuac.app' -maxdepth 8 -type d | head -1)"
[[ -n "${APP}" ]] || fail "no built Hanahuac.app found under ${DD}"
echo "Inspecting bundle: ${APP}"

# Mac Catalyst nests resources under Contents/Resources; iOS bundles put them at the root.
RES="${APP}/Contents/Resources"
[[ -d "${RES}" ]] || RES="${APP}"

echo "== base languages present in the main bundle (always bundled, offline base-only path) =="
for base in en es-MX; do
    [[ -d "${RES}/${base}.lproj" ]] || fail "base language ${base}.lproj missing from main bundle"
    echo "  ok: ${base}.lproj present"
done

echo "== non-base languages declared as On-Demand Resources in the project =="
for code in fr de es-ES ko nah; do
    grep -q "\"lang-${code}\"" "${PBXPROJ}" \
        || fail "lang-${code} is not declared as an on-demand asset tag in the project"
    echo "  ok: lang-${code} declared on-demand"
done

echo "== platform note: on-demand resources in this build's main bundle (informational) =="
embedded=0
for code in fr de es-ES ko nah; do
    if [[ -d "${RES}/${code}.lproj" || -f "${RES}/${code}-geo.json" ]]; then
        embedded=1
    fi
done
if [[ "${embedded}" -eq 1 ]]; then
    echo "  note: ODR resources are embedded in this bundle (expected on Mac Catalyst / Simulator;"
    echo "        on iOS-device/App-Store builds they split into Apple-hosted on-demand packs)."
else
    echo "  on-demand resources are NOT embedded in the main bundle (iOS-device-style split)."
fi

echo "verify-base-only-bundle: PASS — base languages present; non-base languages are on-demand."
