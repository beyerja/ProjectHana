## Goal

Ensure every user-facing string is localized across all six supported languages (en, es-MX, de, fr, ko, nah) with no untranslated keys and no hardcoded English, so the app presents correctly in every language it advertises — and make completeness reproducible/enforced going forward.

## Audit method (reproducible)

- **Static completeness check** — added stdlib-only `scripts/check-l10n-completeness.py`, wired into `just l10n-check` and folded into `just lint` (CI lint job). It parses every `Hanahuac/<code>.lproj/Localizable.strings`, builds the canonical key set as the union of all locales, and asserts every base (en, es-MX) and fully-translated downloadable locale (de, fr, ko) contains the full set. `nah` is treated as an allowed partial subset (nah -> es-MX -> en fallback, per `L10n.swift` `bundleCandidates`) and reported informationally. Non-base values byte-identical to English are surfaced as warnings, gated by a justified `IDENTICAL_VALUE_ALLOWLIST`. Exits non-zero on any missing required key.
- **Runtime completeness check** — added `HanahuacTests/L10nCompletenessTests.swift`, which drives the canonical key set from the en base bundle and asserts every key resolves to a non-key, non-empty value for all `AppLocale` cases through the fallback chain, plus a focused nah-fallback assertion.
- **Hardcoded-string audit** — grepped `Hanahuac/**/*.swift` for `Text("…"`, `.navigationTitle("…"`, `Label/Button/Toggle/Section/Picker/Menu/Stepper/TextField/Link("…"`, `.accessibilityLabel/Hint("…"`, and `.alert("…"` with non-L10n literal arguments.

## Results

- **Locale key counts** (canonical = 156): en 155 -> **156** (after fix), es-MX 156, de 156, fr 156, ko 156, nah 52 (33% — partial by design, remainder served via fallback).
- **Confirmed gap FIXED:** `stats.by_mode` (used at `StatsView.swift:137`, present in es-MX/de/fr/ko) was **missing from the en base** — English users saw the raw key. Added `"stats.by_mode" = "By Quiz Type";` to `Hanahuac/en.lproj/Localizable.strings` adjacent to the other stats keys. No other missing keys across required locales.
- **Untranslated-value warnings:** all flagged values are legitimately shared, not English stubs — "iCloud" (Apple brand), "Multiple Choice"/"Status" (German loanwords), French cognates Correct/Incorrect/Question/Europe, and "%d / 3" (format-only). Each added to the allowlist with justification; the warning list is now empty.
- **Hardcoded strings:** only `Text("Hanahuac")` (`HanahuacWordmark`, `HanahuacLogo.swift:128`) — the app's brand wordmark/proper noun, intentionally not localized. No user-facing translatable literals found; nothing to move.
- **nah convention:** missing nah keys resolving via nah -> es-MX -> en fallback are intentional and acceptable; documented and asserted in `L10nCompletenessTests` and existing `L10nBundleResolutionTests`.
- **ODR integrity:** `just verify-odr-packs` PASS; `project.yml` **unchanged** (fr/de/ko/nah ODR-tagged, en/es-MX always-bundled); no `.lproj` folder references added/removed.

## Summary of changes

- Added `scripts/check-l10n-completeness.py` (stdlib-only) + `just l10n-check` recipe, folded into `just lint`.
- Added `HanahuacTests/L10nCompletenessTests.swift` (runtime completeness + nah-fallback assertions).
- Fixed the one real gap: added missing `stats.by_mode` key to the en base.
- ODR tag contract in `project.yml` unchanged.

## Test plan

- [x] `just l10n-check` PASS (0 missing required keys, warning list empty)
- [x] `just lint` PASS (0 SwiftLint violations, swiftformat clean, ruff clean)
- [x] `just test` -> ** TEST SUCCEEDED ** (includes `L10nCompletenessTests`)
- [x] `just verify-odr-packs` PASS; `project.yml` ODR tag contract intact
