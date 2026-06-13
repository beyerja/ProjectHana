# Story 003 — Localize Geographic Data

## Goal
Add `name_fr`, `name_de`, `name_es` fields to all geographic JSON resource files and update the Swift models to expose a locale-aware `localizedName` API.

## Depends On
Story 001 (`AppLocale` enum must exist).

## JSON Resources to Update
All in `ProjectHana/Resources/`:
- `countries.json` — add `name_fr`, `name_de`, `name_es` per entry; also `capital_fr`, `capital_de`, `capital_es` per entry (capitals are also shown in quiz prompts)
- `rivers.json` — add `name_fr`, `name_de`, `name_es` per entry
- `mountains.json` — add `name_fr`, `name_de`, `name_es` per entry
- `seas.json` — add `name_fr`, `name_de`, `name_es` per entry

Continent labels that appear in data (used in quiz prompts and as display labels):
`"Africa"`, `"Asia"`, `"Europe"`, `"North America"`, `"Oceania"`, `"South America"` — these are strings in the JSON, so they also need translation. Add them to `Localizable.strings` (story 002) rather than to the JSON.

## Tasks

### 1. Update `countries.json`
For each country entry, add:
```json
{
  "id": "...",
  "name": "Germany",
  "name_fr": "Allemagne",
  "name_de": "Deutschland",
  "name_es": "Alemania",
  "capital": "Berlin",
  "capital_fr": "Berlin",
  "capital_de": "Berlin",
  "capital_es": "Berlín",
  ...
}
```
(Some capitals translate, e.g., "Vienna" → "Vienne" in French, "Wien" in German.)

### 2. Update `rivers.json`, `mountains.json`, `seas.json`
Same pattern — add `name_fr`, `name_de`, `name_es` per entry.

### 3. Update Swift models
`Country.swift`, `River.swift`, `MountainRange.swift`, `Sea.swift` — add optional decoded fields and a `localizedName(for:)` method:
```swift
struct Country: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let capital: String
    let capitalFr: String?
    let capitalDe: String?
    let capitalEs: String?
    ...

    func localizedName(for locale: AppLocale) -> String {
        switch locale {
        case .fr: return nameFr ?? name
        case .de: return nameDe ?? name
        case .esMX: return nameEs ?? name
        case .en: return name
        }
    }

    func localizedCapital(for locale: AppLocale) -> String { ... }
}
```

### 4. Add continent label translations to `Localizable.strings`
Keys like `continent.africa`, `continent.asia`, etc., translated in all four language files.

## Note on JSON size
The JSON files will grow roughly 3×. This is acceptable for an educational geography app. No lazy-loading changes are needed.

## Acceptance Criteria
- [ ] `countries.json`, `rivers.json`, `mountains.json`, `seas.json` all have `name_fr`, `name_de`, `name_es` on every entry
- [ ] `countries.json` has `capital_fr`, `capital_de`, `capital_es` on every entry
- [ ] `Country.localizedName(for: .fr)` returns the French name; falls back to English if missing
- [ ] All Swift models decode without errors (existing tests still pass)
- [ ] Continent labels are translated in all four `Localizable.strings` files

## Files Touched
- `ProjectHana/Resources/countries.json`
- `ProjectHana/Resources/rivers.json`
- `ProjectHana/Resources/mountains.json`
- `ProjectHana/Resources/seas.json`
- `ProjectHana/Models/Country.swift`
- `ProjectHana/Models/River.swift`
- `ProjectHana/Models/MountainRange.swift`
- `ProjectHana/Models/Sea.swift`
- All four `Localizable.strings` files (continent keys)
