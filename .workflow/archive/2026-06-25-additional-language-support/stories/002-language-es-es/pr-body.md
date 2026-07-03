## Goal

Add Spanish (Spain) `es-ES` as a **new, distinct base language code** (separate from `es-MX`),
delivered as a **downloadable On-Demand Resources (ODR) pack** with **complete** professional
Castilian Spanish for every UI string and all geo content. `es-ES` is selectable in the picker as
"Español (España)" but is **never auto-selected** from device locale — every `es-*` device locale
still resolves to `.esMX`.

This story ships first among the new languages because `ca` and `eu` (stories 003, 004) fall back
through `es-ES`; its commit compiles and passes on its own.

## Summary of changes

- **`AppLocale.swift`** — add `case esES = "es-ES"`. `matching(_:)` is left unchanged: the existing
  `if language == "es" { return .esMX }` rule remains, so Spain-region devices still default to
  `es-MX` and `es-ES` is never auto-selected.
- **`LanguageCatalog.swift`** — add a `LanguageDescriptor` for `es-ES` (displayName
  "Español (España)", fallbackChain `[.esES, .esMX, .en]`, availability `.downloadablePack`,
  odrTags `[lang-es-ES]`); catalog order matches `AppLocale.allCases`.
- **`es-ES.lproj/Localizable.strings`** — new; complete professional peninsular Castilian Spanish for
  the full `en.lproj` key set (zero missing keys), authored as real Castilian — not a copy of `es-MX`.
- **Geo content** — `name_es_es` / `capital_es_es` added for every country, and `name_es_es` for every
  river, mountain, and sea in `countries.json` / `rivers.json` / `mountains.json` / `seas.json`.
- **`scripts/generate-geo-packs.py`** — add `"es-ES"` to `PACK_LANGUAGES` and `"es-ES": "es_es"` to
  `SUFFIX_BY_CODE`; `Resources/es-ES-geo.json` generated via `just geo-packs`.
- **`project.yml`** — `es-ES.lproj` and `Resources/es-ES-geo.json` declared as ODR resources tagged
  `[lang-es-ES]` and added to `excludes` so they are not bundled; project regenerated via `just generate`.
- **Tests** — `AppLocaleTests` regression: `AppLocale.matching(Locale(identifier: "es_ES")) == .esMX`;
  plus picker native name, `[es-ES, es-MX, en]` fallback resolution, UI-key + geo completeness, and
  per-language progress isolation for `.esES` (reusing story 001 helpers).

## Test plan

- [ ] `just lint`
- [ ] `just test`
- [ ] `just geo-packs-check`
- [ ] `just verify-odr-packs` (`es-ES` not bundled; pack tagged `[lang-es-ES]`)
- [ ] iOS / Mac Catalyst build
- [ ] CI green on the PR

🤖 Generated with [Claude Code](https://claude.com/claude-code)
