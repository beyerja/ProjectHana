# Story 003 — Blocking lint CI workflow

## Goal
Add a fast, blocking per-PR CI workflow that runs every linter and fails on any violation, following
the project's "split CI by speed" convention. Fast lint checks block PRs; slow scanners stay on
schedule/push-to-main (unchanged).

## Acceptance criteria
- New workflow (e.g. `.github/workflows/lint.yml`) triggered on `pull_request` (and `push` to main)
  against main. Runs on `ubuntu-latest` (no macOS needed for these linters; swiftlint/swiftformat run
  on Linux).
- Installs linters via Nix (consistent with flake) or pinned actions — no hardcoded `/nix` paths.
  Using the flake dev shell on the runner is preferred for consistency.
- Each linter step fails the job on any violation (fail-on-violation).
- Path filtering: lint runs when its relevant file types change. The job must not get stuck Pending
  on unrelated PRs — mirror the `ci.yml` pattern (a `changes` detector + skip = pass, OR run the
  cheap lint job unconditionally since it is fast). Document the choice in a comment.
- Does NOT add any slow scanner to the blocking per-PR path; CodeQL/secret-scan conventions untouched.

## Notes
- swiftlint and swiftformat both have Linux builds available via nixpkgs.
- Keep the workflow cheap and fast.
