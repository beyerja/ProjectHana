## Goal

Close the quality-infrastructure gap for the upcoming dep-update-failure-issues work: the repo lints YAML syntax (yamllint) but has no GitHub Actions semantic linter (actionlint) and no `dependabot.yml` schema validation. Actions semantic errors (bad `${{ }}` expressions, invalid trigger/`permissions:` config, shell bugs in `run:` steps) pass yamllint and only surface at runtime — and `workflow_run`/`schedule` triggers only fire from the default branch, so a broken workflow would merge green and silently never fire. This story adds both checks statically to the fast blocking lint gate before stories 001–002 touch `.github/` files.

## Changes

- **flake.nix**: add `actionlint` and `check-jsonschema` to the `linters` tool set that feeds the `.#lint` dev shell (tools come from the flake via direnv; no hardcoded /nix paths).
- **justfile**: new `lint-gha` recipe that runs `actionlint` over `.github/workflows/*.yml` and `check-jsonschema --builtin-schema vendor.dependabot .github/dependabot.yml`; folded into the `lint` umbrella recipe.
- **.github/workflows/lint.yml**: matching actionlint + check-jsonschema steps in the existing fast blocking lint job, using the flake dev shell (no ad-hoc tool installs, no new third-party actions).

Baseline is clean: all existing workflow files and `dependabot.yml` pass the new checks.

## Test plan

- [ ] `nix develop .#lint --command actionlint --version` succeeds
- [ ] `nix develop .#lint --command check-jsonschema --version` succeeds
- [ ] `just lint-gha` passes on the current tree and fails on an injected violation
- [ ] `just lint` includes `lint-gha` and passes
- [ ] CI lint job runs both new checks and is green on this PR

🤖 Generated with [Claude Code](https://claude.com/claude-code)
