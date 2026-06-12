# Feature: Developer Tooling — just + direnv + .envrc

## Goal

Eliminate per-command environment-variable boilerplate that currently burdens every `xcodebuild`, `gh`, `xcrun simctl`, and `bash scripts/agent-log.sh` invocation. Introduce `just` as a task runner and `direnv` + `.envrc` for automatic environment setup, so any developer (or Claude agent) can run short, memorable recipes without manual `DEVELOPER_DIR=...` or `export PATH=...` prefixes.

## Acceptance Criteria

- [ ] `flake.nix` adds `just` and `direnv` to `devShells.default.packages`; `nix develop` resolves cleanly with both tools on PATH
- [ ] `.envrc` is committed to the repo root with the following content (no secrets):
  ```
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  PATH_add "$HOME/.nix-profile/bin"
  ```
  `direnv allow` activates it; `direnv deny` cleanly restores the previous PATH
- [ ] `justfile` is committed to the repo root with all seven recipes below, each working without any env-var prefix:
  - `just test` — runs the full xcodebuild test suite on the iPhone 17 simulator
  - `just build-mac` — builds for Mac Catalyst, ad-hoc signed
  - `just install` — runs build-mac, then atomically: kills any running ProjectHana, removes `/Applications/ProjectHana.app`, copies the new bundle, and opens the app
  - `just pr TITLE` — creates a GitHub PR via `gh pr create`; body read from stdin or a temp file
  - `just pr-list` — lists open PRs via `gh pr list`
  - `just ci BRANCH` — shows CI run status via `gh run list --branch BRANCH`
  - `just log ARGS` — delegates to `bash scripts/agent-log.sh ARGS` (telemetry shortcut)
- [ ] Claude can invoke `just test`, `just install`, and `just log` in agent sessions without prepending any environment-variable exports
- [ ] All existing `nix develop` tooling (xcodegen, xcbeautify, jq, swiftformat) continues to work unchanged

## Constraints

- `.envrc` must use `direnv`'s `PATH_add` helper (not `export PATH=...`) so direnv can restore the path on deactivation
- The `install` recipe must be a single atomic `just` invocation (not a sequence of manual commands)
- No secrets, credentials, or machine-specific paths beyond `DEVELOPER_DIR` (pointing to the standard Xcode location) may be committed in `.envrc`
- `justfile` recipes must work from inside `nix develop` (tools like `gh` and `xcodebuild` are already on PATH via `.envrc` + nix shell)

## Out of Scope

- Homebrew-based installation of `just` or `direnv` (Nix flake is the sole dev-env mechanism)
- CI pipeline changes (GitHub Actions already sets its own environment)
- Any new Swift source files or SwiftData changes
- Automating `direnv allow` in CI (not needed; `.envrc` is sourced explicitly there if required)
