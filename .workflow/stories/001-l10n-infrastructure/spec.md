# Story 001 — L10n Infrastructure

## Goal
Stand up the foundational i18n plumbing: `AppLocale` enum, `LanguageManager` singleton, `.lproj` string bundles for all four languages, and an in-app language picker wired into the UI.

## Background
The app currently has no localization infrastructure. All strings are hardcoded in English. This story creates the foundation that stories 002–004 build on.

## Tasks

### 1. Add `.lproj` bundle directories and stub `Localizable.strings` files
- Create `ProjectHana/en.lproj/Localizable.strings` (English — will be filled in story 002)
- Create `ProjectHana/fr.lproj/Localizable.strings` (French)
- Create `ProjectHana/de.lproj/Localizable.strings` (German)
- Create `ProjectHana/es-MX.lproj/Localizable.strings` (Mexican Spanish)
- Add all four to the Xcode target via `project.yml` (XcodeGen)

### 2. Add `AppLocale` enum
New file: `ProjectHana/L10n/AppLocale.swift`
```swift
enum AppLocale: String, CaseIterable, Identifiable {
    case en    = "en"
    case fr    = "fr"
    case de    = "de"
    case esMX  = "es-MX"

    var id: String { rawValue }
    var displayName: String { /* native name */ }

    // Resolve a Locale to the best-matching AppLocale
    static func matching(_ locale: Locale) -> AppLocale { ... }
}
```
`matching(_:)` checks language code first, then region. Any `es-*` locale resolves to `.esMX`. Unrecognized locales fall back to `.en`.

### 3. Add `LanguageManager`
New file: `ProjectHana/L10n/LanguageManager.swift`
```swift
@Observable final class LanguageManager {
    static let shared = LanguageManager()
    var current: AppLocale
    // persists to UserDefaults key "appLocale"
    // on init resolves Locale.current via AppLocale.matching
}
```

### 4. Inject `LanguageManager` into the SwiftUI environment
In `ProjectHanaApp.swift`, pass `LanguageManager.shared` into the environment (as an `@Observable` object via `.environment(\.languageManager, LanguageManager.shared)` or directly via `.environment(LanguageManager.shared)`).

### 5. Add in-app language picker
New file: `ProjectHana/Views/Settings/LanguagePickerView.swift`
- `List` or `Form` showing the four `AppLocale` cases by `displayName`
- Checkmark on the currently selected locale
- Tapping a row writes to `LanguageManager.shared.current`

Wire the picker into `HomeView` as a toolbar button (gear icon → `LanguagePickerView`).

## Acceptance Criteria
- [ ] Four `.lproj` directories exist and are in the Xcode build target
- [ ] `AppLocale.matching(Locale(identifier: "es-ES"))` returns `.esMX`
- [ ] `AppLocale.matching(Locale(identifier: "ja"))` returns `.en`
- [ ] `LanguageManager` persists and restores the selection across launches (via `UserDefaults`)
- [ ] The in-app picker is reachable from `HomeView` and changing the selection is immediately reflected in `LanguageManager.current`

## Files Touched
- `ProjectHana/L10n/AppLocale.swift` (new)
- `ProjectHana/L10n/LanguageManager.swift` (new)
- `ProjectHana/Views/Settings/LanguagePickerView.swift` (new)
- `ProjectHana/Views/Home/HomeView.swift` (add toolbar button)
- `ProjectHana/ProjectHanaApp.swift` (inject LanguageManager)
- `ProjectHana/en.lproj/Localizable.strings` (new, stub)
- `ProjectHana/fr.lproj/Localizable.strings` (new, stub)
- `ProjectHana/de.lproj/Localizable.strings` (new, stub)
- `ProjectHana/es-MX.lproj/Localizable.strings` (new, stub)
- `project.yml` (add lproj files to target resources)
