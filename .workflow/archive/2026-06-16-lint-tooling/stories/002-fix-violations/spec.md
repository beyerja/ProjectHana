# Story 002 — Fix all existing lint violations

## Goal
With linters wired up (story 001), run each one and fix every pre-existing violation across the repo
so the fail-on-violation gates pass. App behavior must not change.

## Acceptance criteria
- `direnv exec . swiftlint` reports zero violations (serious or warning, given the chosen ruleset).
- `swiftformat --lint` reports no changes needed.
- `ruff check` and `ruff format --check` pass on `scripts/*.py`.
- `shellcheck` passes on all tracked `*.sh` (already green; keep so).
- `nixfmt --check flake.nix` passes.
- `yamllint` passes on all tracked YAML.
- The Swift test suite still passes (`just test` or Mac Catalyst build+test) — no behavior change.
- `just lint` exits 0 locally.

## Notes
- Prefer minimal, mechanical fixes. Where a rule is noisy/inappropriate for this codebase, disabling
  it in the config (story-001 files) is acceptable rather than churning lots of code — but keep the
  ruleset idiomatic and meaningful.
