## Goal

Add Dutch (`nl`) as a **complete-content** downloadable On-Demand Resource (ODR) language with the native display name **"Nederlands"**. The fallback chain `[nl, en]` resolves to English only as a never-hit safety net — every UI key and every geo entity ships a Dutch value.

## Summary of changes

- **Language enum & catalog**: add `case nl` to `AppLocale`; add descriptor in `LanguageCatalog` (displayName "Nederlands", `fallbackChain [.nl, .en]`, availability `.downloadablePack`, `odrTags [lang-nl]`). Catalog count 12 → 13; `nl` added to `FULL_LOCALES` so completeness is enforced.
- **UI strings**: new `Hanahuac/nl.lproj/Localizable.strings` — 156 UI keys fully translated into professional native Dutch, zero missing vs `en`.
- **Geo content**: full coverage — 197 countries (`name_nl` + `capital_nl`), 32 rivers, 23 mountains, 20 seas, all with Dutch values and no gaps. Generated `Hanahuac/Resources/nl-geo.json`.
- **Tooling**: `nl` added to geo-pack generation (`PACK_LANGUAGES` / `SUFFIX_BY_CODE`); durable `scripts/seed-nl-geo.py` added for reproducible seeding.
- **Packaging**: `nl.lproj` + `Resources/nl-geo.json` tagged `[lang-nl]` and excluded from the bundle — downloadable, **not** bundled. Per-language download progress is isolated for `.nl`; `es-MX` device default is unchanged. `Hanahuac.xcodeproj` regenerated.

## Test plan

- [x] `just lint`
- [x] `just test` (picker native name; `[nl, en]` fallback resolution; completeness check — zero missing UI keys + full geo coverage; progress isolation for `.nl`)
- [x] `just geo-packs-check`
- [x] `just verify-odr-packs` (`nl` not bundled)
- [ ] CI green on this PR

🤖 Generated with [Claude Code](https://claude.com/claude-code)
