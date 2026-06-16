# Feature: Comprehensive linting tooling (fail-on-violation)

## Slug
`lint-tooling`

## Run mode
**Meta / tooling run, in-place (no worktree).** This feature edits the workflow tooling itself
(`justfile`, `scripts/`, `flake.nix`, `.github/workflows/`), so per the orchestrator Step 0 guard it
runs in the primary checkout on branch `feat/lint-tooling`. `HANA_FEATURE_SLUG=lint-tooling` is still
exported for branch namespacing and telemetry.

## Summary
Add linters for every meaningful language in the repo and make them **fail-on-violation** so they
block PRs. This requires not only wiring up the tools but also **fixing every existing violation** in
the current codebase so the new gates pass.

## Language scope & tools

| Language | Tool(s) | Notes |
|----------|---------|-------|
| Swift    | **SwiftLint** (lint rules) **and** `swiftformat --lint` | Idiomatic ruleset; both must pass. swiftformat already in flake. |
| Python   | **Ruff** (lint; `ruff check`) | `scripts/*.py`. Also `ruff format --check` for formatting consistency. |
| Shell    | **shellcheck** (already wired via `just lint-sh`) | Keep and fold into the unified lint gate. |
| Nix      | **nixfmt** (`nixfmt --check`) | `flake.nix`. Part of project tooling/CI infra. |
| YAML     | **yamllint** | `.github/workflows/*.yml`, `.github/*.yml`, `project.yml`. |

Skipped (per user judgment, not near-trivial value-add): Markdown, JSON.

## Tooling delivery conventions (from CLAUDE.md / MEMORY)
- All linters provided via the **Nix flake** dev shell + direnv. **No hardcoded `/nix` paths.**
  Invoke through `direnv exec .` like the existing `lint-sh` recipe.
- **Split CI by speed.** All these linters are fast, so they go in a new **blocking per-PR** job/
  workflow (a `Lint` workflow or a job in `ci.yml`). They must NOT be lumped with the slow macOS
  build such that they only run when build files change — linters should run when their own file types
  change. Slow scans (CodeQL etc.) stay on schedule/push-to-main per existing convention.
- Prefer Read/Grep/Glob over Bash for inspection (already a project convention).

## Enforcement
**Fail-on-violation.** Each linter exits non-zero on any violation, failing the PR check. This means
**all pre-existing violations in the repo must be fixed** as part of this feature so the gates are
green on merge.

## Acceptance criteria
1. `flake.nix` provides swiftlint, ruff, nixfmt (or alejandra), yamllint (shellcheck/swiftformat
   already present) in the dev shell — no hardcoded `/nix` paths.
2. Config files exist and are idiomatic: `.swiftlint.yml`, `.swiftformat` (if not already), Ruff
   config (in `pyproject.toml` or `ruff.toml`), `.yamllint` (or inline), nixfmt needs none.
3. `just` exposes lint recipes (e.g. `just lint` running all, plus per-language recipes) that invoke
   tools via `direnv exec .`.
4. A **blocking** CI workflow/job runs every linter on PRs against main, gated by relevant path
   filters, and **fails on any violation**.
5. The entire existing codebase passes every linter (all pre-existing violations fixed). `just lint`
   is green locally and the CI lint check is green on the feature PR.
6. Slow-scan CI conventions are preserved (no slow scanners added to the per-PR blocking path).

## Out of scope
- Markdown / JSON linting.
- Auto-fix-on-commit hooks beyond what already exists (focus is the gate + clean baseline).
- Changing application behavior or non-lint-related refactors.
