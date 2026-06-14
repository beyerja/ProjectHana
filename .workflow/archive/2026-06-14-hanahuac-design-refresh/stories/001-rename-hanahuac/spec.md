# 001 — Rename app to "Hanahuac"

## Goal
Rename the app from the placeholder "ProjectHana" to **Hanahuac** everywhere — display name,
navigation title, Xcode project/target/scheme, bundle identifier, build tooling, README, and all
four localizations (en/fr/de/es-MX). This is identity-only; no app logic changes.

## Scope / Files
- `project.yml`: `name`, `bundleIdPrefix` (`com.projecthana` → `com.hanahuac`),
  `PRODUCT_BUNDLE_IDENTIFIER` (`com.projecthana.app` → `com.hanahuac.app`, and `.tests`),
  target/test names, `INFOPLIST_FILE` paths, source/resource paths.
- **DO A FULL RENAME — no internal-name compromise.** `xcodegen 2.44.1` IS available in the Nix
  dev shell (verified: `nix develop --command xcodegen --version` → 2.44.1, Xcode 26.5). The
  `.xcodeproj` is generated from `project.yml`, so the clean path is: edit `project.yml` →
  `git mv` the source dirs → regenerate with `xcodegen` → update `ci.yml` + `justfile` in lockstep.
  Run xcodegen via: `nix develop --command bash -c 'xcodegen generate'` (nix is at
  `/nix/var/nix/profiles/default/bin`; add it to PATH).
- Rename source directories: `git mv ProjectHana Hanahuac` and `git mv ProjectHanaTests HanahuacTests`.
  Delete the old `ProjectHana.xcodeproj` and regenerate (xcodegen will emit `Hanahuac.xcodeproj`).
- **Exact rename surface (already mapped — do not re-derive):**
  - Module/target name `ProjectHana` → `Hanahuac`. This breaks `@testable import ProjectHana` in
    all 14 test files under `ProjectHanaTests/` — update each to `@testable import Hanahuac`.
  - `ProjectHana/ProjectHanaApp.swift` → `Hanahuac/HanahuacApp.swift`; rename `struct ProjectHanaApp`.
  - `ProjectHanaTests/ProjectHanaTests.swift` → `HanahuacTests/HanahuacTests.swift`.
  - `scripts/install-mac.sh`: scheme, `-project`, app product name, `/Applications/ProjectHana.app`.
  - `flake.nix`: `description` and derived-data references.
  - There is NO translatable app-name string in any `.lproj` (display name comes from
    `INFOPLIST_KEY_CFBundleDisplayName`), so no `Localizable.strings` edits are needed for the name.
- `justfile`: every recipe that references the `ProjectHana` scheme / `ProjectHana.app` /
  derivedData path must use the new scheme + app product name so build/test/sim recipes still work.
- `README.md`: title and all references.
- Display name: `Info.plist` `CFBundleDisplayName` / `CFBundleName` (or generated equivalent) →
  "Hanahuac".
- Navigation title / wordmark strings in code (e.g. HomeView large title) → "Hanahuac".
- Localizations: update `en/fr/de/es-MX` `Localizable.strings` for any user-facing app-name string.
  "Hanahuac" is a proper noun — keep it identical across all four locales (do not translate it).
- `flake.nix` / any tooling referencing the old name, if applicable.
- **CI coupling (critical — must update in lockstep):** `.github/workflows/ci.yml` hardcodes
  `-scheme ProjectHana` and path filters `ProjectHana/**`, `ProjectHanaTests/**`,
  `ProjectHana.xcodeproj/**`. Because we ARE doing a full rename, you MUST update ci.yml's scheme,
  `-project`, and all path filters to `Hanahuac/**`, `HanahuacTests/**`, `Hanahuac.xcodeproj/**`,
  or CI will break / stop triggering. The `justfile` similarly hardcodes the scheme, project,
  `ProjectHana.app` product name, and `/tmp/ProjectHana-*-build` derivedData paths — update all.

## Acceptance Criteria
- [ ] Bundle identifier is `com.hanahuac.app` (and `com.hanahuac.app.tests`) in the built product.
- [ ] Display name shown under the icon and the in-app title read "Hanahuac".
- [ ] `project.yml` carries the new name + bundle id; the Xcode project, target, and scheme reflect it.
- [ ] `just build-sim`, `just test`, `just build-mac`, and screenshot/launch recipes all succeed
      after the rename (recipes reference the new scheme/app name).
- [ ] README references "Hanahuac" (no stray "ProjectHana" in user-facing docs).
- [ ] All 4 localizations consistent; "Hanahuac" not translated.
- [ ] App builds for iOS and macOS (Catalyst) and tests pass.

## Notes
- Do NOT change app logic, models, scheduler, or quiz behavior.
- This is a FULL rename: no "ProjectHana" should remain anywhere except inside `.workflow/`
  (historical workflow state/archives) and git history. Verify with
  `grep -rn ProjectHana --exclude-dir=.workflow --exclude-dir=.git --exclude-dir=.build-mac .`
  returning nothing before marking the story done.
- Regenerate the project with xcodegen and confirm `just build-sim`, `just test`, and
  `just build-mac` succeed against the new `Hanahuac` scheme.
