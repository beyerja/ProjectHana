## Goal

Make the set of available languages and their metadata (code, native display name, fallback chain, bundled vs. downloadable) **data-driven** rather than a hand-maintained per-language `switch` in `AppLocale`. This is the foundation every later story in the downloadable-language-packs feature reads from: the picker, the L10n fallback chain, and the geo-name resolver all derive their language list and fallback order from one catalog instead of duplicated switches.

Story 1 of 6 — merges into the `feat/downloadable-language-packs` integration branch. Scope is limited to the existing 6 languages (en, fr, de, es-MX, ko, nah); no new languages are added.

## Summary of changes

- Introduce a single data-driven language catalog (`LanguageCatalog` / `[LanguageDescriptor]`) as the source of truth for language code, native display name, and per-language fallback chain.
- Each descriptor records whether the language is a **bundled** base language (en, es-MX) or a **downloadable** pack language (fr, de, ko, nah). This flag is defined here for consumption by later stories.
- Re-back `AppLocale` with the catalog while preserving its public surface (`displayName`, `fallsBackThroughSpanish` / its replacement, `matching(_:)`, `allCases`/equivalent enumeration) — call sites are unchanged.
- Derive the fallback chain from catalog data instead of a boolean `switch` (ko/nah: selected → es-MX → en; fr/de: selected → en; base languages map to themselves/en).
- `AppLocale.matching(_:)` still resolves device locales exactly as before, including the Spanish-variant and Nahuatl ISO-639-3 mappings (nah, nhn, nch, ncj, ngu, nhe).
- Add tests covering catalog lookup, display names, fallback-chain derivation, and locale matching.

## Test plan

- [ ] Existing `AppLocaleTests` pass unchanged in behavior
- [ ] Existing `LanguageManagerTests` pass unchanged in behavior
- [ ] New catalog tests cover lookup, display names, fallback-chain derivation, and locale matching
- [ ] No user-visible behavior change (pure internal re-architecture)
