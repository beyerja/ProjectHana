# Story 002 — Localize UI Strings

## Goal
Replace every hardcoded English string in the SwiftUI views with localized string keys, and populate all four `Localizable.strings` files with the corresponding translations.

## Depends On
Story 001 (`.lproj` bundles and `LanguageManager` must exist).

## Inventory of Strings to Localize
Based on the current codebase:

| Key | English | Context |
|-----|---------|---------|
| `home.categories` | "Categories" | HomeView section header |
| `home.category.countries` | "Countries" | Category tile |
| `home.category.rivers` | "Rivers" | Category tile |
| `home.category.mountains` | "Mountains" | Category tile |
| `home.category.seas` | "Seas" | Category tile |
| `home.view_progress` | "View Progress" | HomeView link label |
| `quiz.mode.map_tap.title` | "Map Tap Quiz" | QuizModePickerView |
| `quiz.mode.map_tap.desc` | "Tap the correct country on the map" | QuizModePickerView |
| `quiz.mode.type_capital.title` | "Type the Capital" | QuizModePickerView |
| `quiz.mode.type_capital.desc` | "\"What is the capital of X?\"" | QuizModePickerView |
| `quiz.mode.name_country.title` | "Name the Country" | QuizModePickerView |
| `quiz.mode.name_country.desc` | "\"Which country has X as its capital?\"" | QuizModePickerView |
| `quiz.mode.multiple_choice.title` | "Multiple Choice" | QuizModePickerView |
| `quiz.mode.multiple_choice.desc` | "Pick the capital from 4 options" | QuizModePickerView |
| `quiz.cards_due.singular` | "card due" | QuizModePickerView |
| `quiz.cards_due.plural` | "cards due" | QuizModePickerView |
| `settings.language` | "Language" | LanguagePickerView nav title |
| `settings.language.picker_title` | "App Language" | LanguagePickerView section header |

(Add any additional strings discovered during implementation.)

## Tasks

### 1. Update SwiftUI views to use `String(localized:)` / `LocalizedStringKey`
- `HomeView.swift`: wrap "Categories", "Countries", "Rivers", "Mountains", "Seas", "View Progress"
- `QuizModePickerView.swift`: wrap all mode titles, descriptions, "cards due" variants
- `LanguagePickerView.swift`: nav title and section header (added in story 001)
- Any other views with visible user-facing strings

Use `LocalizedStringKey` literals in SwiftUI `Text()` calls where possible (SwiftUI resolves them automatically). Use `String(localized: "key")` where a `String` is required.

### 2. Populate `en.lproj/Localizable.strings`
All keys from the inventory with their English values.

### 3. Populate `fr.lproj/Localizable.strings`
French translations for all keys.

### 4. Populate `de.lproj/Localizable.strings`
German translations for all keys.

### 5. Populate `es-MX.lproj/Localizable.strings`
Mexican Spanish translations for all keys.

## Note on `LanguageManager` and String Resolution
Since the app uses a custom `LanguageManager` (not just the system locale), views must resolve strings using the `Bundle` for the selected locale. A helper like:
```swift
extension String {
    static func localized(_ key: String) -> String {
        // look up in bundle for LanguageManager.shared.current
    }
}
```
…or using `String(localized:bundle:locale:)` ensures the right bundle is used regardless of the system locale. Design this carefully so it works across all views without boilerplate.

## Acceptance Criteria
- [ ] No hardcoded English user-visible strings remain in `.swift` view files (grep check)
- [ ] All four `Localizable.strings` files are non-empty and contain the same set of keys
- [ ] Switching `LanguageManager.current` to `.fr` causes all UI labels to render in French
- [ ] Switching to `.de` renders German; switching to `.esMX` renders Spanish
- [ ] Switching back to `.en` renders English

## Files Touched
- `ProjectHana/Views/Home/HomeView.swift`
- `ProjectHana/Views/Quiz/QuizModePickerView.swift`
- `ProjectHana/Views/Settings/LanguagePickerView.swift`
- Any other view files with user-visible strings
- `ProjectHana/L10n/` — possibly a string-lookup helper
- `ProjectHana/en.lproj/Localizable.strings`
- `ProjectHana/fr.lproj/Localizable.strings`
- `ProjectHana/de.lproj/Localizable.strings`
- `ProjectHana/es-MX.lproj/Localizable.strings`
