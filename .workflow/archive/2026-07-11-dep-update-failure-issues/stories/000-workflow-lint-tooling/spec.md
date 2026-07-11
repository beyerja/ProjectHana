# Story 000 — workflow lint tooling (setup)

## Title
Add actionlint + dependabot.yml schema validation to the lint gate

## Goal
Close the one quality-infrastructure gap that materially endangers this feature's deliverables:
the repo lints YAML *syntax* (yamllint, local + CI) but has **no GitHub Actions semantic linter**
(actionlint) and **no dependabot.yml schema validation**. Every deliverable of this feature is
`.github/` config — an edited `dependabot.yml`, a modified `update-flake-lock.yml`, and a brand-new
`dep-update-failure-monitor.yml` with nontrivial `workflow_run` / `schedule` / expression logic.

## Why this is material (not a generic setup story)

- Actions semantic errors (invalid event/trigger config, bad `${{ }}` context expressions, wrong
  `permissions:` keys, shell bugs in `run:` steps) pass yamllint and surface **only at runtime** —
  and `workflow_run`/`schedule` triggers only fire from the default branch, so a broken monitor
  workflow would merge green and then silently never fire. actionlint catches these statically.
- Story 001's acceptance criteria explicitly rely on validating `dependabot.yml` "by schema/lint"
  (the `github-actions` Dependabot run cannot be re-triggered from the CLI). Pure yamllint cannot
  provide schema validation; `check-jsonschema --builtin-schema vendor.dependabot` can.

## Scope

1. **Flake dev shell:** add `actionlint` and `check-jsonschema` to the lint tool set in `flake.nix`
   (same `linters` list that feeds `.#lint`; both are in nixpkgs). No hardcoded /nix paths — tools
   come from the flake via direnv, per project convention.
2. **justfile:** new `lint-gha` recipe that
   - runs `actionlint` over `.github/workflows/*.yml` (via `direnv exec .`), and
   - runs `check-jsonschema --builtin-schema vendor.dependabot .github/dependabot.yml`.
   Fold `lint-gha` into the `lint` umbrella recipe (mirroring `l10n-check`).
3. **CI (`.github/workflows/lint.yml`):** add matching actionlint + check-jsonschema steps to the
   existing fast blocking lint job (tools from `nix develop .#lint`, same pattern as the other
   steps). Keep it in the fast per-PR gate — both tools run in seconds.
4. Fix any pre-existing violations the new linters surface in the current `.github/` files (expected
   to be zero or trivial; the point is a clean baseline before stories 001–002 touch these files).

## Non-goals
- No app code, no Xcode build, no changes outside `flake.nix`, `flake.lock` (if the shell change
  requires it — prefer not), `justfile`, and `.github/workflows/lint.yml`.
- No new slow/scheduled scanning workflows (project convention: fast checks block PRs).

## Acceptance Criteria

- [ ] `nix develop .#lint --command actionlint --version` and
      `nix develop .#lint --command check-jsonschema --version` both succeed (tools in the flake
      lint shell; equivalently available via `direnv exec .`).
- [ ] `just lint-gha` exists, runs actionlint over all tracked `.github/workflows/*.yml` and
      schema-validates `.github/dependabot.yml` with the vendored Dependabot schema, and fails
      on violation.
- [ ] `just lint` includes `lint-gha` and passes on the current tree.
- [ ] `.github/workflows/lint.yml` runs both new checks in the existing blocking lint job, using
      the flake dev shell (no ad-hoc tool installs, no pinned third-party actions added without
      checking current versions).
- [ ] All existing workflow files and `dependabot.yml` pass the new checks (baseline clean).
