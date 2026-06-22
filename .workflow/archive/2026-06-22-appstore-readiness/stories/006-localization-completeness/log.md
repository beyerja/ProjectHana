# Log — Localization completeness audit & fix

2026-06-21 break-tasks: DONE, 11 tasks

## Audit method

- Added `scripts/check-l10n-completeness.py` (stdlib-only): parses every
  `Hanahuac/<code>.lproj/Localizable.strings`, builds the canonical key set as the union of all
  locales, and asserts every base (en, es-MX) and fully-translated downloadable locale (de, fr, ko)
  contains the full set. nah is treated as an allowed partial subset (nah -> es-MX -> en fallback,
  per L10n.swift bundleCandidates) and reported informationally. Non-base values byte-identical to
  English are surfaced as warnings, gated by a justified `IDENTICAL_VALUE_ALLOWLIST`.
- Wired into `just l10n-check` and folded into `just lint` (CI lint job) so completeness is enforced
  going forward. Exits non-zero on any missing required key.
- Runtime complement: `HanahuacTests/L10nCompletenessTests.swift` asserts every canonical key
  (driven from the en base bundle) resolves to a non-key, non-empty value for all `AppLocale` cases
  through the fallback chain, plus a focused nah-fallback assertion.
- Hardcoded-string audit: grepped `Hanahuac/**/*.swift` for `Text("…"`, `.navigationTitle("…"`,
  `Label/Button/Toggle/Section/Picker/Menu/Stepper/TextField/Link("…"`, `.accessibilityLabel/Hint("…"`,
  `.alert("…"` with non-L10n literal arguments.

## Results

- Locale key counts (canonical = 156): en 155 -> 156 (after fix), es-MX 156, de 156, fr 156, ko 156,
  nah 52 (33% — partial by design, rest via fallback).
- Confirmed gap FIXED: `stats.by_mode` (used at StatsView.swift:137, present in es-MX/de/fr/ko) was
  MISSING from the en base — English users saw the raw key. Added `"stats.by_mode" = "By Quiz Type";`
  to `Hanahuac/en.lproj/Localizable.strings` adjacent to the other stats keys. No other missing keys
  across required locales.
- Untranslated-value warnings: all flagged values are legitimately shared, not English stubs —
  "iCloud" (Apple brand), "Multiple Choice"/"Status" (German loanwords), French cognates
  Correct/Incorrect/Question/Europe, and "%d / 3" (format-only). All added to the allowlist with
  justifications; warning list is now empty.
- Hardcoded-string findings: only `Text("Hanahuac")` (HanahuacWordmark, HanahuacLogo.swift:128) — the
  app's brand wordmark/proper noun, intentionally not localized. No user-facing translatable literals
  found; nothing to move.
- nah convention: missing nah keys resolving via nah -> es-MX -> en fallback are intentional and
  acceptable; documented and asserted in L10nCompletenessTests + existing L10nBundleResolutionTests.
- ODR integrity: `just verify-odr-packs` PASS; `project.yml` unchanged (fr/de/ko/nah ODR-tagged,
  en/es-MX always-bundled); no `.lproj` folder references added/removed.
- Checks: `just l10n-check` PASS, `just lint` PASS (0 SwiftLint violations, swiftformat clean, ruff
  clean), `just test` -> ** TEST SUCCEEDED **.

2026-06-21 implement-story: DONE — all 11 tasks (l10n completeness check + just wiring, en
stats.by_mode fix, identical-value allowlist, runtime + nah-fallback tests), no hardcoded
user-facing strings found, ODR contract intact; lint + test green.

2026-06-21 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/153

2026-06-21 independent-review: APPROVED — completeness gate + runtime test correct, real en stats.by_mode gap fixed, nah partial handled, no new deps, ODR contract intact; 3 non-blocking inline nits (es-MX skipped in identical-value check, union-vs-en canonical, warnings non-failing).

2026-06-21 code-owner-review: APPROVED — independent second eye; negative test confirms gate catches missing required keys, nah-fallback chain + StatsView.swift:137 call site verified, union==en confirmed, no new deps, ODR contract intact, first reviewer's 3 findings concurred non-blocking. Build & Test green; gitleaks correctly main-only (no event-miss). Formal Hanahuac-Bot APPROVED submitted via wrapper and confirmed by read-back.

2026-06-21 merge-pr: DONE

2026-06-21 verify-story: DONE — all 5 ACs PASS at merged commit 3e3c01e. l10n-check PASS (156 canonical keys; en/es-MX/de/fr/ko full, nah 52/33% partial-by-design via fallback). lint PASS. test ** TEST SUCCEEDED ** (incl. L10nCompletenessTests). verify-odr-packs PASS (fr/de/ko/nah ODR-tagged, en/es-MX untagged, project.yml unchanged). stats.by_mode present in all required locales. Only hardcoded literal is Text("Hanahuac") brand wordmark. PR #153 body documents audit method+results. CI green (Build & Test pass).
