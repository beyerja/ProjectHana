# Workflow Log — lint-tooling

## Step 0 — Setup
- Derived slug: `lint-tooling`.
- Run mode: **in-place (no worktree)** — meta/tooling run; edits `justfile`, `scripts/`, `flake.nix`,
  `.github/workflows/`. Per orchestrator Step 0 guard, tooling-touching runs stay in the primary
  checkout. Exported `HANA_FEATURE_SLUG=lint-tooling`. Created branch `feat/lint-tooling` off `main`.

## Step 1 — Clarify
- Clarification already completed by user before orchestration resumed. Answers:
  - Languages: Swift/Python/Shell definite; added Nix + YAML by judgment; skip Markdown/JSON.
  - Swift: SwiftLint + swiftformat --lint, idiomatic ruleset.
  - Enforcement: fail-on-violation (fix all existing violations).
  - Python: Ruff.
- Spec written to `.workflow/feature.md`.

## Step 2 — Break stories
- 3 stories: 001-provision-linters, 002-fix-violations, 003-lint-ci. Ordered so each is coherent;
  001 wires tools, 002 makes baseline green, 003 gates in CI.

## Step 3 — Assess health
- main is clean, existing CI (build/test, codeql, secret-scan) green.
- Verified all required linters resolve in nixpkgs: swiftlint 0.63.3, ruff 0.15.16,
  nixfmt-rfc-style 1.3.1, yamllint 1.37.1, swiftformat 0.61.1, shellcheck 0.11.0.
- No setup stories prepended.

## Step 4 — Story loop
- 001-provision-linters: DONE. Added swiftlint/ruff/nixfmt/yamllint to flake.nix; configs
  (.swiftlint.yml, .swiftformat, pyproject.toml, .yamllint); `just lint` + per-language recipes via
  `direnv exec .`.
- 002-fix-violations: DONE. Applied swiftformat (64 files) + swiftlint --fix; tuned configs for
  idiomatic domain/test patterns (single-char identifiers allowed, `master` allowed via
  override_allowed_terms, function_parameter_count headroom); manual fixes for force_try (PreviewStore
  inline disable), 1 long test line, ruff B023/B905/RUF005/RUF007; dropped PTH (high-churn pathlib
  rewrite) from ruff select. `just lint` exits 0; `just test` TEST SUCCEEDED (no behavior change).
- 003-lint-ci: DONE. Added .github/workflows/lint.yml — fast blocking per-PR gate running all linters
  via `nix develop` on ubuntu-latest, fail-on-violation, runs unconditionally (cheap; never stuck
  Pending). Slow scanners untouched. Added __pycache__ to .gitignore.

## Step 5 — Create PR
- PR #86 opened: feat/lint-tooling -> main. https://github.com/beyerja/ProjectHana/pull/86

## Step 6 — Wait for CI
- Run 1: Lint job FAILED (20s) — `nix develop` could not evaluate on ubuntu: default devShell
  includes macOS-only xcodegen/xcbeautify. Fix: added `devShells.lint` (linters only) and pointed CI
  at `nix develop .#lint`. Pushed 8271c9f. Build & Test + gitleaks passed. Re-polling.

## Step 7 — Verify feature
- STATUS: DONE.
  - `just lint` exits 0 locally across Swift/Python/Shell/Nix/YAML.
  - CI Lint check PASS (46s) on PR #86; Build & Test + gitleaks also PASS.
  - Negative test: ruff and yamllint return exit 1 on deliberately bad input → fail-on-violation
    confirmed (CI `run:` steps propagate the non-zero exit, failing the gate).
  - All acceptance criteria in feature.md satisfied; slow-scan CI conventions untouched.

## Step 8 — Evaluate workflow
2026-06-16T17:16:47Z evaluate-workflow: DONE
Telemetry outliers: implement-story (high retries 18/26 over history; this run's feature-level
  CI-fix loop was a lint-shell-on-Linux miss caught only in CI).
Permission remediation: distribution this run dominated by inspection noise (cd 89, echo/cat/ls/grep,
  git diff/show) — not allowlistable per security bar. Clean recurring workflow signature: `just lint`
  (and family). Applied: added `Bash(just lint*)` + `Bash(just --dry-run lint*)` to .claude/settings.json
  (deterministic, side-effect-bounded just recipes — auto-apply tier). Proposed: none.
Phase 2a flags: none — agent files recently audited (#73/#64); raw size is not bloat.
Phase 2b: applicable (7 distinct dates). Prior eval edits (#81 permission phase, #83 Read/Grep/Glob)
  applied. implement-story carries the highest retry rate; adding a `just lint` pre-commit check to
  implement-story should reduce future lint-CI rework loops (Supported direction).
Improvements:
  1. implement-story.md project-checks step now runs `just lint` before `just test` so the new
     fail-on-violation gate is satisfied locally instead of failing in CI.
  2. .claude/settings.json allowlists the lint recipes to cut future permission prompts.
