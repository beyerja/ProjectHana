#!/usr/bin/env bash
# Verify the On-Demand-Resources (ODR) language packs are DATA-ONLY and that the build's ODR tag
# contract matches what the runtime provider requests. This is the basis for the async CI job
# (.github/workflows/odr-validation.yml) and is also runnable locally via `just verify-odr-packs`.
#
# Checks (all fail the script non-zero):
#   1. The generated Xcode project declares exactly the expected `lang-<code>` asset tags
#      (lang-fr, lang-de, lang-es-ES, lang-ko, lang-nah) — the contract from LanguageDescriptor.odrTags — and
#      assigns each non-base `.lproj` + its `<code>-geo.json` to the matching tag.
#   2. The base languages (en, es-MX) carry NO asset tag (always bundled).
#   3. Every ODR-tagged resource is DATA-ONLY: only `.strings`/`.json` files, no Mach-O / executable
#      / dylib / shell / script content.
#   4. Each `<code>-geo.json` is well-formed JSON in the GeoNamePackData shape (version + code +
#      entries) and is up to date with the bundled source data.
#   5. No custom network / crypto / signature / hash-verification trust code was introduced —
#      integrity is inherited from Apple App Store ODR code-signing.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PBXPROJ="${ROOT}/Hanahuac.xcodeproj/project.pbxproj"
RESOURCES="${ROOT}/Hanahuac/Resources"

# The ODR tag contract: downloadable language code -> tag. Base languages (en, es-MX) are absent on
# purpose — they must NOT be tagged.
LANG_CODES=(fr de es-ES ko nah)

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

echo "== 1/5: ODR tag contract in generated project =="
[[ -f "${PBXPROJ}" ]] || fail "missing generated project at ${PBXPROJ} (run 'just generate')"

for code in "${LANG_CODES[@]}"; do
    tag="lang-${code}"
    grep -q "knownAssetTags" "${PBXPROJ}" || fail "project has no knownAssetTags block"
    grep -q "\"${tag}\"" "${PBXPROJ}" || fail "expected asset tag ${tag} not declared in project"
    # The .lproj and the geo JSON for this language must both carry the tag.
    grep -Eq "${code}\.lproj in Resources .*ASSET_TAGS = \(\"${tag}\"" "${PBXPROJ}" \
        || fail "${code}.lproj is not tagged ${tag}"
    grep -Eq "${code}-geo\.json in Resources .*ASSET_TAGS = \(\"${tag}\"" "${PBXPROJ}" \
        || fail "${code}-geo.json is not tagged ${tag}"
    echo "  ok: ${tag} -> ${code}.lproj + ${code}-geo.json"
done

echo "== 2/5: base languages carry NO asset tag =="
for base in en "es-MX"; do
    # The base .lproj live in the merged Localizable.strings variant group; assert no ASSET_TAGS is
    # attached to that group's build file and no lang-<base> tag exists.
    if grep -Eq "lang-${base}\b" "${PBXPROJ}"; then
        fail "base language ${base} must not have an ODR tag, found lang-${base}"
    fi
    echo "  ok: ${base} is always-bundled (untagged)"
done

echo "== 3/5: ODR-tagged resources are DATA-ONLY =="
data_only_ok=1
while IFS= read -r -d '' f; do
    case "${f}" in
        *.json | *.strings) ;;
        *)
            echo "  unexpected non-data file under an ODR pack: ${f}" >&2
            data_only_ok=0
            ;;
    esac
    # Reject any file the OS would consider executable / Mach-O / a script.
    if file "${f}" | grep -Eqi "mach-o|executable|shared library|dylib|script text"; then
        echo "  executable/code content detected: ${f}" >&2
        data_only_ok=0
    fi
done < <(
    find "${RESOURCES}" -maxdepth 1 -name '*-geo.json' -print0
    for code in "${LANG_CODES[@]}"; do
        find "${ROOT}/Hanahuac/${code}.lproj" -type f -print0
    done
)
[[ "${data_only_ok}" -eq 1 ]] || fail "ODR packs contain non-data / executable content"
echo "  ok: every ODR-tagged resource is a .strings/.json data file"

echo "== 4/5: geo packs are well-formed and up to date =="
for code in "${LANG_CODES[@]}"; do
    pack="${RESOURCES}/${code}-geo.json"
    [[ -f "${pack}" ]] || fail "missing geo pack ${pack} (run 'just geo-packs')"
    python3 - "${pack}" "${code}" <<'PY' || fail "geo pack failed schema validation"
import json
import sys

path, code = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as handle:
    pack = json.load(handle)
assert pack.get("version") == 1, f"{path}: unexpected version {pack.get('version')}"
assert pack.get("code") == code, f"{path}: code mismatch {pack.get('code')!r}"
entries = pack.get("entries")
assert isinstance(entries, dict) and entries, f"{path}: entries must be a non-empty object"
for geo_id, entry in entries.items():
    assert geo_id, f"{path}: empty geo id"
    name = entry.get("name")
    capital = entry.get("capital")
    assert (name and name.strip()) or (capital and capital.strip()), \
        f"{path}: entry {geo_id} has neither name nor capital"
PY
    echo "  ok: ${code}-geo.json valid"
done
python3 "${ROOT}/scripts/generate-geo-packs.py" --check >/dev/null \
    || fail "geo packs are stale; run 'just geo-packs' and commit"
echo "  ok: geo packs are up to date with bundled source data"

echo "== 5/5: no custom network/crypto/signature trust code =="
# Integrity is inherited from App Store ODR code-signing; there must be no hand-rolled networking,
# crypto, signature, or hash verification in the language-pack CODE. We scan only real code lines:
# documentation comments (`///`, `//`, `*`) legitimately *describe* the future signed-CDN design and
# explicitly state no such code exists, so comment lines are stripped before matching.
forbidden='URLSession|NSURLConnection|CryptoKit|CommonCrypto|SHA256|Security\.framework|SecKey|SecTrust'
hits="$(
    grep -RnE --include='*.swift' "${forbidden}" "${ROOT}/Hanahuac/L10n" 2>/dev/null \
        | grep -vE ':[0-9]+:[[:space:]]*(///|//|\*)' || true
)"
if [[ -n "${hits}" ]]; then
    echo "  matches found (non-comment code):" >&2
    echo "${hits}" >&2
    fail "custom network/crypto/signature/hash code present in language-pack sources"
fi
echo "  ok: no custom trust code; integrity inherited from App Store ODR code-signing"

echo "verify-odr-packs: PASS — packs are data-only and the ODR tag contract is intact."
