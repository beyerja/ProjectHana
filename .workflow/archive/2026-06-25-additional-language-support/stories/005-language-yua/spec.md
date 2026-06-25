# 005 — Language: Màaya t'àan / Yucatec Maya (yua)

## Title
Add Yucatec Maya `yua` as a downloadable language (best-effort content, es-MX fallback)

## Goal
Add `yua` (Yucatec Maya, ISO 639-3) as a downloadable ODR language with native display name
"Màaya t'àan". Author as much real, professional Yucatec Maya as feasible for UI strings and geo
content; genuine gaps may rely on the fallback chain `[yua, es-MX, en]`. NO new dependency:
`es-MX` already exists, so this story can ship independently of es-ES.

## Files to change
- `Hanahuac/L10n/AppLocale.swift` — add `case yua`. `yua` MAY auto-detect via the catalog-driven
  `matching(_:)` code-lookup (code `yua` == rawValue); confirm `es-*` mapping is unaffected.
- `Hanahuac/L10n/LanguageCatalog.swift` — add descriptor (displayName "Màaya t'àan",
  fallbackChain `[.yua, .esMX, .en]`, availability `.downloadablePack`, odrTags `[lang-yua]`).
  Order matches `AppLocale.allCases`. (This routes through es-MX, matching `fallsBackThroughSpanish`.)
- `Hanahuac/yua.lproj/Localizable.strings` — NEW; professional Yucatec Maya for the ~85 keys
  (best-effort; genuine gaps may be omitted to fall back through es-MX → en).
- `Hanahuac/Resources/countries.json` — add `name_yua` + `capital_yua` (best-effort coverage).
- `Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json` — add `name_yua` (best-effort).
- `scripts/generate-geo-packs.py` — add `"yua"` to `PACK_LANGUAGES`, `"yua": "yua"` to `SUFFIX_BY_CODE`.
- `Hanahuac/Resources/yua-geo.json` — generated via `just geo-packs`.
- `project.yml` — add `yua.lproj` + `Resources/yua-geo.json` tagged `[lang-yua]`; add both to
  `excludes`. Regenerate via `just generate`.
- Tests: picker native name; fallback chain `[yua, es-MX, en]` resolution (a gap resolves to es-MX
  before en); progress isolation for `.yua`.

## Acceptance Criteria
1. Picker shows "Màaya t'àan" for `yua`.
2. Fallback chain `[yua, es-MX, en]` resolves correctly; a gap in `yua` resolves to the `es-MX`
   value before `en` (test asserts the chain order through Spanish).
3. Content: real Yucatec Maya authored to the extent feasible; remaining gaps fall back (permitted).
4. ODR: `yua.lproj` + `yua-geo.json` exist, tagged `[lang-yua]`, excluded from bundle;
   `just geo-packs-check` and `just verify-odr-packs` pass; `yua` is NOT bundled.
5. Per-language progress isolated for `.yua`.
6. Catalog/enum invariants hold.
7. `just lint`, `just test`, `just geo-packs-check`, `just verify-odr-packs`, and an
   iOS/Catalyst build pass. CI green on the PR.

## Notes
- Suffix: `yua`. ISO 639-3 code.
- NO new dependency (es-MX already exists). Can run in parallel with ca/eu in principle, but
  sequence to avoid shared-file conflicts (see stories.md ordering).
