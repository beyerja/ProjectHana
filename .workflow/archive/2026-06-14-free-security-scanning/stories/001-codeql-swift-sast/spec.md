# Story 001 — CodeQL Swift SAST workflow

## Goal

Add a CodeQL static-analysis (SAST) workflow that analyzes the Hanahuac Swift codebase,
runs on pull requests to `main` and pushes to `main`, and uploads results to the GitHub
Security tab. CodeQL fully supports Swift; Swift is a compiled language so CodeQL must
observe a build, which uses the project's existing `xcodebuild`/`just` toolchain on
`macos-15`.

## Acceptance Criteria

- [ ] `.github/workflows/codeql.yml` exists.
- [ ] Triggers: `pull_request` targeting `main`, `push` to `main`, plus a weekly
      `schedule` (so the default branch baseline stays fresh).
- [ ] Language matrix includes `swift`.
- [ ] Runs on `macos-15` (Swift analysis requires macOS + a build).
- [ ] Uses `github/codeql-action@v4` (init, autobuild-or-manual-build, analyze). The build
      step uses the project toolchain (`just build-mac` or the equivalent `xcodebuild`
      invocation already used by `ci.yml`), not a hardcoded path.
- [ ] `security-events: write` permission is granted so results upload to the Security tab.
- [ ] No hardcoded `/nix/...` paths anywhere in the workflow.
- [ ] The workflow is syntactically valid YAML and the action version is the latest
      verified major (v4 as of 2026-06-14).

## Notes

- This story changes only CI config (a `.github/workflows/` file). No Swift source changes,
  so `just test` is not the relevant gate — validity is verified by YAML lint + the workflow
  running green on its own PR.
- The CodeQL build mirrors `ci.yml`: project `Hanahuac.xcodeproj`, scheme `Hanahuac`,
  destination `platform=macOS,variant=Mac Catalyst`, code signing disabled.
