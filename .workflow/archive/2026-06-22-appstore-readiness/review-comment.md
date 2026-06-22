<!-- independent-review -->
## Independent review — Round 1: CHANGES_REQUESTED

Cold-context 4-eye review of the aggregate `appstore-readiness` integration PR (HEAD `c4f6674`). Most of the diff is already-individually-reviewed-and-merged story content (#145, #147, #149, #150, #151, #153, #155); per scope I focused on (a) the main-integration merge resolution and (b) cross-story interactions that only surface in aggregate. The merge resolution itself (project.yml ODR-language section + `PrivacyInfo.xcprivacy` explicit-resource/exclude, regenerated `Hanahuac.xcodeproj`) is clean: `PrivacyInfo.xcprivacy` appears exactly once in the Copy-Resources phase, and the App Store INFOPLIST keys are present in both Debug and Release configs.

### Blocking finding (aggregate-only regression)

**The localization completeness gate silently excludes `es-ES`** — `scripts/check-l10n-completeness.py` ([inline comment](https://github.com/beyerja/ProjectHana/pull/156#discussion_r3449913076)).

The merge integrated #154, which shipped `Hanahuac/es-ES.lproj/Localizable.strings` as a *complete downloadable* locale plus an `AppLocale.esES` case. But the gate's hardcoded `ALL_LOCALES` is only `en, es-MX, de, fr, ko, nah` — `es-ES` is never loaded, never contributes to the canonical key union, and is never checked for missing or untranslated keys. The gate reports `PASS — all required locales contain the full canonical key set` while a 7th shipping locale is entirely unverified.

Concretely, `es-ES.lproj` currently has ~132 keys vs 156 canonical — it is missing the `a11y.*` keys added by #150/#151 in this same feature branch. Those keys still resolve at runtime via `es-ES → es-MX → en` (so it is not a crash), but the feature AC "Localization completeness is verified across all 6 languages" is violated: the merge introduced a locale that falls outside the gate the feature itself added.

**Fix:** add `es-ES` to `FULL_LOCALES`, back-fill the missing `es-ES` keys until the gate passes (extend the byte-identical allowlist as needed), and ideally derive the locale list from the `Hanahuac/*.lproj` directories so future locales can't slip the gate again.

### Verified clean (in scope)

- Merge resolution of `project.yml` (ODR `es-ES.lproj` exclude + `es-ES-geo.json` ODR tagging) coexists correctly with the appstore-readiness `PrivacyInfo.xcprivacy` exclude + explicit `buildPhase: resources` entry; no duplicate Copy-Resources entry in the regenerated pbxproj.
- App Store build settings (`ITSAppUsesNonExemptEncryption=NO`, `LSApplicationCategoryType=public.app-category.education`, `UILaunchScreen_Generation=YES`, `MARKETING_VERSION=1.0`, `CURRENT_PROJECT_VERSION=1`) present in both build configs.
- Out-of-scope items (code signing, iCloud/CloudKit, App Store Connect uploads, usage-strings for unused APIs, external deps) correctly not touched.

Verdict: **CHANGES_REQUESTED** — fix the es-ES gate gap, then re-request review.
