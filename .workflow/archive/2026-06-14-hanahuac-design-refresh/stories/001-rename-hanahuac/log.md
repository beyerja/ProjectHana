# Story 001 — Rename to Hanahuac — log

- Full rename applied EVERYWHERE: source dirs `ProjectHana/`→`Hanahuac/`,
  `ProjectHanaTests/`→`HanahuacTests/`; module/target `Hanahuac`; `@testable import Hanahuac` in
  all test files; `HanahuacApp.swift`; `project.yml` (name, bundleIdPrefix `com.hanahuac`,
  targets, paths, bundle ids `com.hanahuac.app`/`.tests`); `flake.nix`; `justfile`;
  `.github/workflows/ci.yml` (scheme + path filters); `scripts/install-mac.sh`; `README.md`.
- Project regenerated from `project.yml` with `xcodegen` → `Hanahuac.xcodeproj`.
  Added an explicit `schemes:` block (shared `Hanahuac` scheme) so CI's `-scheme Hanahuac` works
  deterministically (the original relied on a manually-committed Xcode scheme).
- Added `GENERATE_INFOPLIST_FILE: YES` to both targets (the old `INFOPLIST_FILE` line pointed at a
  non-existent plist; the original pbxproj generated the plist).
- Build VERIFIED: `xcodebuild` for iOS Simulator → **BUILD SUCCEEDED** (with a clean Apple
  toolchain env).
- Intentionally NOT renamed: the GitHub repo `beyerja/ProjectHana` (external resource; referenced
  in `justfile` pr-list/ci recipes and the README CI badge) and the local clone directory path.
  Renaming the GitHub repo is a separate, user-owned action.
- Environment fixes made so local builds work from the nix dev shell:
  `.envrc` now `use flake`; `.claude/settings.local.json` sets `ZDOTDIR` → `.claude/shell/.zshenv`
  (sources nix-daemon.sh) so the harness shell reaches nix; `flake.nix` switched to `mkShellNoCC`
  so the dev shell no longer leaks `CC/NIX_LDFLAGS/SDKROOT` into `xcodebuild`.

DONE — verified locally; CI is the remaining gate.
