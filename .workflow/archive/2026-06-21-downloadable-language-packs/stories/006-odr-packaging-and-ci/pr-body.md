## Goal

Make the per-language pack resources (the fr/de/ko/nah `.lproj` UI strings + their geo-name JSON data)
ship as version-tagged On-Demand Resources built per app version — removing them from the always-bundled
main binary — plus the build/packaging configuration and an async (non-per-PR) ODR validation job. This
realizes the "installed size stays flat" goal and the release-tied pack versioning constraint.

This is the final story (006) of the **downloadable-language-packs** feature.

## Summary of changes

- **ODR packaging of non-base languages** — `fr`/`de`/`ko`/`nah` `.lproj` directories and their
  `<code>-geo.json` packs are assigned `lang-<code>` ODR tags and excluded from the main app target's
  always-bundled resources. `en` and `es-MX` remain bundled (offline base-only path).
- **Build/packaging config** — `project.yml` and the generated `Hanahuac.xcodeproj/project.pbxproj`
  carry the ODR tag assignments so the build produces Apple-hosted, code-signed ODR packs tied to the
  app version (packs refresh on app update; no independent OTA updates).
- **Geo-pack generator** — `scripts/generate-geo-packs.py` produces the per-language
  `<code>-geo.json` packs reproducibly; generated `fr-/de-/ko-/nah-geo.json` added under
  `Hanahuac/Resources/`.
- **Verification scripts (data-only, no trust code)** —
  - `scripts/verify-odr-packs.sh` confirms each ODR tag is DATA-ONLY (no executable content).
  - `scripts/verify-base-only-bundle.sh` confirms the app builds/launches with zero packs present.
  - Wired through `justfile` recipes.
- **Async validation CI** — `.github/workflows/odr-validation.yml` runs on `push: main` and on a
  schedule, NOT as a per-PR gate; findings are tracked. Fast PR checks stay blocking and fast.
- **Docs** — `docs/odr-packaging.md` documents how packs are tagged/produced for a reproducible
  release process; `README.md` links it.
- **Tests** — `HanahuacTests/ODRTestSupport.swift` plus updates to
  `L10nBundleResolutionTests.swift` and `LocalizedQuizPromptTests.swift` cover bundle resolution with
  packs absent/present.

## Acceptance criteria mapping

- [x] Non-base resources (fr/de/ko/nah `.lproj` + geo JSON) assigned ODR tags and excluded from the
      main binary; en + es-MX stay bundled — `project.yml`, `project.pbxproj`.
- [x] ODR tags organized as `lang-<code>` matching the provider (story 004) requests; build produces
      Apple-hosted, code-signed ODR packs.
- [x] Pack versioning tied to app release; packs refresh on update; no independent OTA updates —
      documented in `docs/odr-packaging.md`.
- [x] Build/packaging config documented for a reproducible release process — `docs/odr-packaging.md`.
- [x] Fast PR checks remain blocking; ODR validation runs async (push:main + schedule), not a PR gate —
      `.github/workflows/odr-validation.yml`.
- [x] Validation confirms packs are DATA-ONLY and the app builds/launches with zero packs present —
      `scripts/verify-odr-packs.sh`, `scripts/verify-base-only-bundle.sh`.
- [x] No custom network/crypto/signature-verification trust code; integrity inherited from Apple App
      Store ODR code-signing.

## Test plan

- [ ] `just` ODR verification recipes pass (`verify-odr-packs`, `verify-base-only-bundle`).
- [ ] Async `odr-validation` workflow runs green on push to main / schedule.
- [ ] Swift tests pass (`L10nBundleResolutionTests`, `LocalizedQuizPromptTests`, `ODRTestSupport`).
- [ ] App builds and launches with zero packs present (offline base-only path).
