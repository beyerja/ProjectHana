# Feature: Internationalization (i18n) — French, German, and Spanish Support

## Goal
Add multi-language support to ProjectHana so that all content — UI strings and geographic proper nouns — is fully translated into French, German, and Mexican Spanish. The app should auto-detect the device locale and also let users override the language in-app.

## Supported Languages
| Locale | Code | Notes |
|--------|------|-------|
| English | `en` | Current base; no changes needed to existing strings |
| French | `fr` | Full translation of UI + geographic names |
| German | `de` | Full translation of UI + geographic names |
| Spanish (Mexican) | `es-MX` | Default Spanish; `es` used as fallback so all Spanish locales (es-ES, es-AR, etc.) resolve to this content |

## Scope of Translation

### UI Strings
All hardcoded English text visible to the user:
- Navigation titles, tab bar labels
- Button and action labels ("Exit", "Next", "View Progress", etc.)
- Category names ("Countries", "Rivers", "Mountain Ranges", "Seas")
- Quiz prompts and result messages
- Settings / language picker labels

### Geographic Proper Nouns
All named geographic entities in the JSON resource files:
- Country names (and capital names)
- River names
- Mountain range names
- Sea names
- Continent labels

Each JSON resource entry gains `name_fr`, `name_de`, `name_es` fields alongside the existing English `name` field. Swift models are updated to expose a locale-aware `localizedName` computed property.

## Locale Selection
- **Auto-detect**: On first launch, the app reads `Locale.current` and picks the best-matching supported language.
- **In-app override**: A language picker in Settings lets the user select any supported language. Selection is persisted to `UserDefaults` and overrides the device locale.
- **Fallback chain**: If a locale is unsupported (e.g., Japanese), fall back to English.
- **Spanish fallback**: `es-MX` translations are served for all `es-*` locales (Spain, Argentina, etc.).

## Architecture

### `LanguageManager`
An `@Observable` singleton that:
- Exposes `currentLocale: AppLocale` (enum: `.en`, `.fr`, `.de`, `.esMX`)
- Persists the selection to `UserDefaults`
- On init, resolves the device locale to the best-matching `AppLocale`
- Is injected into the SwiftUI environment so views and quiz logic can read it

### Localizable Strings
- Uses Apple's `.lproj` / `Localizable.strings` (or `Localizable.xcstrings`) infrastructure
- One strings file per language: `en.lproj/Localizable.strings`, `fr.lproj/Localizable.strings`, `de.lproj/Localizable.strings`, `es-MX.lproj/Localizable.strings`
- UI strings use `String(localized:)` or `LocalizedStringKey` in SwiftUI

### Geographic Data
- JSON files gain `name_fr`, `name_de`, `name_es` optional string fields
- Swift models expose `func localizedName(for locale: AppLocale) -> String` (falls back to `name` if translation missing)
- Quiz session factories read from `LanguageManager` to pick the right field for prompts and answer choices

## Acceptance Criteria
1. Switching the device locale (or the in-app picker) to French, German, or Spanish causes all UI text to render in that language.
2. Quiz questions and answer choices use the localized geographic name — e.g., a French-locale user sees "Allemagne" not "Germany".
3. Any `es-*` device locale (es-ES, es-AR, …) resolves to the Spanish content.
4. The in-app language picker shows the four supported languages; selecting one persists and applies immediately without relaunch.
5. Falling back to English when the device locale is unsupported (e.g., Japanese).
6. The app name on the home screen is unchanged ("ProjectHana").
7. All existing tests pass; new unit tests cover locale resolution and localized name lookup.

## Out of Scope
- App Store localized metadata / screenshots
- Right-to-left layout support
- Pluralization rules (can be addressed in a follow-up)
- Accessibility string localization
