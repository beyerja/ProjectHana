# Stories: i18n — French, German, Spanish Support

## Status Legend
- `[ ]` pending
- `[x]` done
- `[-]` skipped

## Stories

- [ ] [001 — L10n Infrastructure](stories/001-l10n-infrastructure/spec.md): Add `.lproj` bundles, `Localizable.strings` for all 4 languages, `AppLocale` enum, `LanguageManager` singleton, and in-app language picker UI wired into Settings.
- [ ] [002 — Localize UI Strings](stories/002-localize-ui-strings/spec.md): Replace all hardcoded UI strings in SwiftUI views with `String(localized:)` / `LocalizedStringKey` and populate all four `Localizable.strings` files.
- [ ] [003 — Localize Geographic Data](stories/003-localize-geo-data/spec.md): Add `name_fr`, `name_de`, `name_es` fields to all JSON resource files and update Swift models to expose `localizedName(for:)`.
- [ ] [004 — Localize Quiz Prompts](stories/004-localize-quiz/spec.md): Thread `LanguageManager` into quiz session factories so question prompts and answer choices use localized geographic names.
- [ ] [005 — L10n Tests](stories/005-l10n-tests/spec.md): Unit tests for locale resolution logic, `localizedName` fallback behaviour, and quiz prompt generation in each supported language.
