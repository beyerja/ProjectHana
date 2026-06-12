# Story 005 — L10n Unit Tests

## Goal
Add unit tests covering locale resolution, localized name lookup with fallback, and quiz prompt generation in each supported language.

## Depends On
Stories 001–004 (all implementation must be in place).

## Tasks

### 1. `AppLocaleTests.swift`
Test `AppLocale.matching(_:)` resolution:
- `Locale(identifier: "en")` → `.en`
- `Locale(identifier: "en-GB")` → `.en`
- `Locale(identifier: "fr")` → `.fr`
- `Locale(identifier: "fr-CA")` → `.fr`
- `Locale(identifier: "de")` → `.de`
- `Locale(identifier: "de-AT")` → `.de`
- `Locale(identifier: "es-MX")` → `.esMX`
- `Locale(identifier: "es-ES")` → `.esMX`
- `Locale(identifier: "es-AR")` → `.esMX`
- `Locale(identifier: "ja")` → `.en` (fallback)
- `Locale(identifier: "zh-Hans")` → `.en` (fallback)

### 2. `LocalizedGeoNameTests.swift`
Test `localizedName(for:)` on each model:
- A `Country` with all four name fields returns the correct one per locale
- A `Country` missing `nameFr` falls back to `name` when locale is `.fr`
- A `River`, `MountainRange`, and `Sea` each return their localized name correctly

### 3. `LocalizedQuizPromptTests.swift`
Test factory methods return correctly localized prompts:
- `MultipleChoiceSession.countryCapitalQuestions` with locale `.fr` produces a prompt containing the French country name
- Same factory with locale `.de` produces German name in prompt
- `continentQuestions` with locale `.esMX` produces Spanish continent labels in options
- English locale produces same output as pre-feature (regression guard)

### 4. `LanguageManagerTests.swift`
- `LanguageManager` init with a saved `UserDefaults` value restores the correct `AppLocale`
- Setting `current` writes to `UserDefaults` and is readable back

## Acceptance Criteria
- [ ] All new tests pass (`just test` green)
- [ ] All existing tests still pass (no regressions)
- [ ] At least one test per supported locale for each test class above

## Files Touched
- `ProjectHanaTests/AppLocaleTests.swift` (new)
- `ProjectHanaTests/LocalizedGeoNameTests.swift` (new)
- `ProjectHanaTests/LocalizedQuizPromptTests.swift` (new)
- `ProjectHanaTests/LanguageManagerTests.swift` (new)
