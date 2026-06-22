# 006 — Localization completeness audit & fix

## Title
Verify and fix localization completeness across all 6 languages (en, es-MX, de, fr, ko, nah)

## Goal
Ensure every user-facing string is localized in all six supported languages with no untranslated
keys and no hardcoded English, so the app presents correctly in every language it advertises.

## Acceptance Criteria
Traceable to feature.md:

- [ ] All six languages (en, es-MX, de, fr, ko, nah) are audited for completeness: every key
      present in the base/en `.lproj` strings exists and is translated (not left in English) in
      each of es-MX, de, fr, ko, nah. (feature.md AC: localization completeness)
- [ ] The codebase is audited for hardcoded user-facing English (string literals in views that
      should go through the L10n/localization layer); any found are moved to localized keys.
- [ ] Any gaps found (missing keys, untranslated values, hardcoded strings) are fixed across the
      affected `.lproj` files / source. (feature.md AC: fix any gaps found)
- [ ] The audit method and results are recorded in the PR description so completeness is
      reproducible.
- [ ] App builds and CI stays green; ODR-tagged non-base `.lproj` packs (fr/de/ko/nah) remain
      correctly tagged in `project.yml` (do not break the ODR tag contract). (feature.md
      Constraints; project.yml ODR setup)

## Notes / Constraints
- fr/de/ko/nah `.lproj` are On-Demand-Resource folder references in `project.yml`; en/es-MX are
  always-bundled. Preserve this structure when editing strings.
- No new dependencies. (feature.md Constraints)
- Independent of other stories.
