## Goal

Add Polish (`pl`) as a **COMPLETE-content** downloadable On-Demand Resources (ODR) language, with
native display name **"Polski"**. The fallback chain `[pl, en]` resolves to English only as an
untriggered safety net — every UI key and every geo entity ships a real Polish value. This mirrors
the merged Italian (`it`) story.

## Summary of changes

- **`Hanahuac/L10n/AppLocale.swift`** — added `case pl` (auto-detects via catalog-driven `matching(_:)`
  code lookup; `es-*` mapping unaffected).
- **`Hanahuac/L10n/LanguageCatalog.swift`** — added descriptor: displayName "Polski",
  `fallbackChain [.pl, .en]`, availability `.downloadablePack`, `odrTags [lang-pl]`. Order matches
  `AppLocale.allCases`. Catalog count 11 → 12.
- **`Hanahuac/pl.lproj/Localizable.strings`** — NEW; all **156 UI keys** professionally translated to
  Polish with correct diacritics (ą, ć, ę, ł, ń, ó, ś, ź, ż).
- **`Hanahuac/Resources/countries.json`** — `name_pl` + `capital_pl` for every country.
- **`Hanahuac/Resources/rivers.json` / `mountains.json` / `seas.json`** — `name_pl` for every entity.
- **`scripts/generate-geo-packs.py`** — added `"pl"` to `PACK_LANGUAGES` and `"pl": "pl"` to
  `SUFFIX_BY_CODE`; `pl` added to `FULL_LOCALES` completeness gate.
- **`Hanahuac/Resources/pl-geo.json`** — generated ODR pack via `just geo-packs`, tagged `[lang-pl]`.
- **`project.yml`** — added `pl.lproj` + `Resources/pl-geo.json` tagged `[lang-pl]`, both added to
  `excludes`; `Hanahuac.xcodeproj` regenerated via `just generate`.
- **Tests** — picker native name, fallback chain `[pl, en]` resolution, COMPLETENESS check (zero
  missing UI keys vs `en.lproj`, full geo coverage so en fallback is never hit), per-language progress
  isolation for `.pl`.

## Acceptance criteria (from spec)

1. Picker shows "Polski" for `pl`.
2. Fallback chain `[pl, en]` resolves correctly (test).
3. COMPLETE content: zero missing UI keys vs `en.lproj`; every country/capital/river/mountain/sea has
   a `pl` value (completeness check passes — fallback to en never hit).
4. ODR: `pl.lproj` + `pl-geo.json` exist, tagged `[lang-pl]`, excluded from bundle; `pl` is NOT
   bundled.
5. Per-language progress isolated for `.pl`.
6. Catalog/enum invariants hold.
7. Local gates pass.

## Test plan

- [x] `just lint`
- [x] `just test`
- [x] `just geo-packs-check`
- [x] `just verify-odr-packs`
- [x] `just verify-base-only`
- [x] `just build-mac` (Catalyst/macOS build)
- [ ] CI green on the PR

🤖 Generated with [Claude Code](https://claude.com/claude-code)
