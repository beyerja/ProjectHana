## Goal

Introduce the `LanguagePackProvider` seam the whole downloadable-language-packs feature pivots on, and ship it with a working **bundled** implementation so the build stays green and offline-usable before any ODR/CDN code exists. Geo-name translations move off hardcoded per-language struct fields into data-only pack data keyed by language code.

This is **story 2 of 6** and targets the feature branch `feat/downloadable-language-packs`.

## Summary of changes

- Added a `LanguagePackProvider` protocol defining the seam: given a language code, it resolves the string-lookup source and the geo-name translation data for that language, plus availability/state so call sites never branch on "ODR vs bundled vs CDN".
- Added a concrete **bundled** provider conforming to the protocol using the resources that ship in the app today (base-language `.lproj` + bundled geo JSON). With only the bundled provider wired in, the app is fully usable with zero packs downloaded.
- Added a versioned, schema-validated pack-data model for geo names (language code → geo id → localized name/capital) as JSON. The loader schema-validates before use; a parse/validation failure degrades safely to the bundled fallback and never crashes (no `fatalError` on pack data).
- Reworked geo models (`Country`, `River`, `MountainRange`, `Sea`) so localized names no longer depend on hardcoded per-language fields (`nameFr`, `capitalKo`, …) + per-locale `switch` arms; localized names are sourced from the active language's pack data keyed by language code, kept working via the bundled provider.
- Pack data is DATA-ONLY (strings + JSON), never executable. No custom network/crypto/signature-verification code is introduced; the protocol is shaped so the future signed-CDN provider plugs in later without touching call sites.
- Added tests covering the bundled provider, pack-data schema validation (including a malformed pack degrading to fallback), and geo-name resolution via pack data.

## Test plan

- [ ] Build succeeds with only the bundled provider wired in
- [ ] App is fully usable with zero packs downloaded
- [ ] Bundled provider returns correct string source + geo-name data per language
- [ ] Pack-data schema validation rejects malformed packs and degrades to bundled fallback (no crash)
- [ ] Geo-name resolution via pack data returns correct localized names/capitals
- [ ] Existing `LocalizedGeoNameTests` pass against the new mechanism

🤖 Generated with [Claude Code](https://claude.com/claude-code)
