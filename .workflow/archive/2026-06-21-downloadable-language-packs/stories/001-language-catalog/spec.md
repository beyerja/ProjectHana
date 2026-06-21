# 001 — Data-driven language catalog

## Title
Replace per-language `switch` in `AppLocale` with a data-driven language catalog

## Goal
Make the set of available languages and their metadata (code, native display name,
fallback chain, whether a language is bundled vs. downloadable) data-driven rather than
a hand-maintained per-language `switch` in `AppLocale`. This is the foundation every later
story reads from: the picker, the L10n fallback chain, and the geo-name resolver all derive
their language list and fallback order from one catalog instead of duplicated switches.

Scope is limited to the EXISTING 6 languages (en, fr, de, es-MX, ko, nah). No new languages.

## Background (current state)
- `Hanahuac/L10n/AppLocale.swift` hardcodes `displayName`, `fallsBackThroughSpanish`, and
  `matching(_:)` as per-case `switch` statements.
- `AppLocale.allCases` is used by `LanguagePickerView` and tests to enumerate languages.

## Acceptance Criteria
- [ ] A single data-driven catalog (e.g. `LanguageCatalog` / `[LanguageDescriptor]`) is the
      source of truth for: language code, native display name, and the per-language fallback
      chain (selected → es-MX → en for ko/nah; selected → en for fr/de; base languages map to
      themselves/en).
- [ ] Each descriptor records whether the language is a bundled base language (en, es-MX) or a
      downloadable pack language (fr, de, ko, nah). This flag is consumed by later stories but
      defined here.
- [ ] `AppLocale` continues to compile and expose the same public surface used by call sites
      (`displayName`, `fallsBackThroughSpanish` or its replacement, `matching(_:)`,
      `allCases`/equivalent enumeration), now backed by the catalog rather than inline switches.
- [ ] `AppLocale.matching(_:)` still resolves device locales exactly as before, including the
      Spanish-variant and Nahuatl ISO-639-3 mappings (nah, nhn, nch, ncj, ngu, nhe).
- [ ] The fallback chain is derived from catalog data, not from a boolean `switch`. Adding a
      language later would mean adding a catalog entry, not editing a switch (to the extent
      feasible without actually adding languages now).
- [ ] Existing `AppLocaleTests` and `LanguageManagerTests` pass unchanged in behavior; new
      tests cover catalog lookup, display names, fallback-chain derivation, and locale matching.
- [ ] No behavior change visible to the user; this is a pure internal re-architecture.

## Out of Scope
- The `LanguagePackProvider` abstraction (story 002).
- Any ODR / download behavior.
- Geo-name model changes (story 002/003).
- Adding new languages.
