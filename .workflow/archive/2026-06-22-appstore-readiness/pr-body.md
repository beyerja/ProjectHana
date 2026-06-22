## Goal

Bring Hanahuac to a state where it would pass App Store technical/compliance review and present as a polished product on **iOS, iPad, and macOS** — limited to work that does **not** require a paid Apple Developer account.

This is the **aggregate feature PR** for the `appstore-readiness` feature. It bundles **7 story PRs that were each independently reviewed (cold-context 4-eye review) and merged into `feat/appstore-readiness`** before this integration PR was opened.

## Constituent stories (all already reviewed + merged into this branch)

- **#145** — Build config & versioning: `MARKETING_VERSION` 1.0 / `CURRENT_PROJECT_VERSION` 1, `ITSAppUsesNonExemptEncryption=NO`, `LSApplicationCategoryType` = Education, launch screen generation enabled (full-screen, no letterboxing).
- **#147** — Privacy manifest: `PrivacyInfo.xcprivacy` declaring no tracking, no collected data types, and the required-reason API for `UserDefaults` (`NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`). Audit confirmed UserDefaults is the only required-reason API in use — no others declared.
- **#149** — Privacy policy doc: `docs/privacy-policy.md`, suitable to host and reference from App Store Connect; claims verified against code (no data collected or transmitted).
- **#150** — Accessibility (quiz flows): VoiceOver labels/hints/values + Dynamic Type across the text, multiple-choice, and learning quiz flows; shared `a11y.*` localization namespace (19 keys x 6 locales) + resolution test.
- **#151** — Accessibility (map quiz): VoiceOver labels/values/hints + button traits on MapKit annotations (previously invisible to VoiceOver); chrome collapsed into accessible elements with no color reliance; Dynamic Type reflow; 4 new `a11y.map.*` keys + extended test.
- **#153** — Localization completeness gate: stdlib-only completeness check (`scripts/check-l10n-completeness.py` + `just l10n-check`, folded into `just lint`) + runtime test; fixed missing `en` `stats.by_mode` key; `nah` confirmed as an intentional partial subset via `nah -> es-MX -> en` fallback.
- **#155** — macOS/iPad presentation + Mac Catalyst app-icon fix: dropped `"platform":"ios"` from the AppIcon so the single-size universal 1024 icon also covers Mac Catalyst (icon-idiom warning gone); iPad/macOS layout adaptation verified (full-width, no clipping/letterboxing).

## Scope

App Store readiness **assessment + remediation** across iOS / iPad / macOS.

**Out of scope** (no paid Apple Developer account): code signing, iCloud/CloudKit sync (remains gated OFF behind `CLOUDKIT_SYNC`), and App Store Connect uploads (screenshots/metadata/nutrition-label/age-rating). No new capabilities or usage-description strings were added for APIs the app does not use. **Zero external dependencies** added (SwiftUI · SwiftData · MapKit only).

## Integration

- This branch was re-integrated with the latest `origin/main` (merge commit `c4f6674`, which pulled in #154 es-ES among others).
- `just lint` and `just test` **pass post-merge**.

## Test plan

- [x] Each constituent story PR independently reviewed (cold-context) and CI-green before merge into `feat/appstore-readiness`.
- [x] `just lint` passes post-merge (includes SwiftLint/SwiftFormat/Ruff/shellcheck/nixfmt/yamllint + l10n completeness gate).
- [x] `just test` passes post-merge.
- [x] Mac Catalyst + iPad builds succeed under free/Personal-Team signing; iPad runtime renders full-width with no clipping/letterboxing.
- [x] Localization complete across all 6 languages (en, es-MX, de, fr, ko, nah); no untranslated keys, no hardcoded user-facing English.
- [x] VoiceOver + Dynamic Type verified across quiz flows and the MapKit map quiz.
