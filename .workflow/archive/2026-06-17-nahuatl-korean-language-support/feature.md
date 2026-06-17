# Feature: Korean and Nahuatl language support

## Summary
Add two new in-app languages to Hanahuac: **Korean (`ko`)** and **generic Nahuatl (`nah`)**.
Both must localize the **UI strings** and the **geographic content** (country/river/sea/mountain-range
names and country capitals). Translations are best-effort, self-generated.

## Confirmed decisions (from clarification)
1. **Languages:** Korean (`ko`), generic Nahuatl (`nah`).
2. **Scope:** UI strings **and** geographic content for both languages.
3. **Quality & fallback:** Best-effort self-generated translations. Where no reliable translation
   exists for a given string/name, fall back to **Mexican Spanish** (existing es-MX / `nameEs`
   content), then to **English** as the last resort. The effective fallback chain is:
   **selected language → Mexican Spanish (es-MX) → English.**
4. **Display names (native script):** Korean = "한국어", Nahuatl = "Nāhuatl".
5. **Auto-detection:** Detect from the device locale on first launch (same as existing languages),
   with manual override always available in the language picker.
6. **Non-goals:** Nothing beyond the above. Not region-specific Nahuatl variants (generic only);
   not translation review/QA tooling; not RTL changes (both langs are LTR).

## Current architecture (re-established)
- `AppLocale` enum (`Hanahuac/L10n/AppLocale.swift`): cases `en`, `fr`, `de`, `esMX = "es-MX"`.
  Provides `displayName`, `id`, and `static matching(_:)` for device-locale resolution. Spanish
  variants map to `.esMX`; unrecognized → `.en`.
- `LanguageManager` (`Hanahuac/L10n/LanguageManager.swift`): `@Observable`, persists the selection
  via `PreferenceStore` and restores it; otherwise resolves from `Locale.current` via
  `AppLocale.matching`.
- `L10n` (`Hanahuac/L10n/L10n.swift`): resolves UI strings from the `<code>.lproj` bundle for the
  current `AppLocale`. **`bundle(for:)` currently falls back exact-locale → `en`.**
- UI strings: `Hanahuac/<code>.lproj/Localizable.strings` for `en`, `fr`, `de`, `es-MX`
  (~122 keys; es-MX file is 157 lines incl. comments).
- Geographic content models — `Country`, `River`, `Sea`, `MountainRange` (`Hanahuac/Models/`) —
  carry optional `nameFr`/`nameDe`/`nameEs` (and `Country` also `capitalFr/De/Es`) decoded from
  `Hanahuac/Resources/*.json` (snake_case keys `name_fr`, `name_de`, `name_es`, etc.). Each model's
  `localizedName(for:)` switches on `AppLocale`, falling back to English `name` when a field is nil.
- `LanguagePickerView` (`Hanahuac/Views/Settings/LanguagePickerView.swift`) iterates the locales for
  the picker (driven by `AppLocale.allCases`).
- Xcode project (`Hanahuac.xcodeproj/project.pbxproj`): `knownRegions` lists `es-MX` (etc.), and a
  Localizable.strings **variant group** has a `PBXFileReference` per locale. New `.lproj` files must
  be registered here or they won't be bundled.

## Fallback-logic change required (decision #3)
Two fallback paths must implement **new-language → es-MX → English**:
- **UI strings (`L10n.bundle(for:)`):** for `.ko`/`.nah`, the candidate chain must be
  `[<code>, "es-MX", "en"]` so a missing key falls through to Mexican Spanish, then English.
  (Existing `fr`/`de` behavior is intentionally left unchanged: `[<code>, "en"]`.)
- **Geographic content (`localizedName`/`localizedCapital`):** for `.ko`/`.nah` the chain must be
  `nameKo ?? nameEs ?? name` (resp. `nameNah ?? nameEs ?? name`, and capitals analogously), i.e.
  prefer the new language, then Mexican Spanish, then English.

## Acceptance criteria
- The picker shows two new entries, "한국어" and "Nāhuatl", selectable and persisted across launches.
- Selecting Korean/Nahuatl immediately re-renders UI strings and geographic names in that language
  without an app restart (consistent with current in-app switching).
- On a device whose locale is Korean, the app auto-selects Korean on first launch; manual override
  still works. (Nahuatl has no standard device locale auto-match expectation; resolve `nah`/`nhn`
  style codes to `.nah` if present, otherwise it is reachable only via manual selection.)
- Any UI string not present in the ko/nah `Localizable.strings` renders the es-MX value if present,
  else the English value — never a raw key.
- Any geographic name/capital lacking a ko/nah value renders the es-MX value if present, else English.
- All existing languages (en/fr/de/es-MX) behave exactly as before (no regressions).
- New `.lproj` files are registered in the Xcode project (knownRegions + variant group) so they ship
  in the bundle.
- Unit tests cover: `AppLocale.matching` for `ko` (and any `nah` mapping), the new fallback chains
  for both UI strings and geographic content, and picker enumeration including the two new cases.

## Out of scope / risks
- Translation accuracy is best-effort; not professionally reviewed. Nahuatl geographic/UI coverage
  will be partial by design — the es-MX fallback is what makes that acceptable.
