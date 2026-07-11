# Tasks — 000 workflow lint tooling

Story: add actionlint + `check-jsonschema` (Dependabot schema) to the lint gate across the
flake dev shell, the justfile, and the CI lint workflow, with a clean baseline.

Grounding (verified in the worktree):
- `flake.nix` has a single `linters` list (swiftlint, swiftformat, ruff, shellcheck, nixfmt,
  yamllint) shared by the `default` and `lint` dev shells — both new tools go there and only
  there. Both `actionlint` and `check-jsonschema` exist in nixpkgs; adding packages from the
  already-locked nixpkgs input must NOT change `flake.lock` (do not run `nix flake update`).
- `justfile` umbrella is `lint: lint-swift lint-py lint-sh lint-nix lint-yaml l10n-check`;
  per-tool recipes use `direnv exec . <tool>` and the `git ls-files` + bash-array pattern
  (see `lint-sh` / `lint-yaml`).
- `.github/workflows/lint.yml` has one blocking `lint` job; each step is
  `nix develop .#lint --command …` (multi-file steps use the `bash -c` + `git ls-files`
  pattern).
- Files the new linters will scan: `.github/workflows/{ci,codeql,lint,odr-validation,secret-scan,update-flake-lock}.yml` and `.github/dependabot.yml`.

## Tasks

- [x] 001: Add `actionlint` and `check-jsonschema` to the `linters` list in `flake.nix`
      (with one-line purpose comments matching the existing entries' style). Keep the change
      inside the existing list so both the default shell and `.#lint` pick the tools up; the
      edit must stay `nixfmt --check`-clean and must not touch `flake.lock`. Verify with
      `nix develop .#lint --command actionlint --version` and
      `nix develop .#lint --command check-jsonschema --version` (and `direnv exec .` locally).

- [x] 002: Add a `lint-gha` recipe to `justfile`: a `#!/usr/bin/env bash` +
      `set -euo pipefail` recipe (matching `lint-sh`/`lint-yaml`) that
      (a) collects tracked workflow files via `git ls-files '.github/workflows/*.yml' '.github/workflows/*.yaml'`
      into a bash array and runs `direnv exec . actionlint` on them (empty-set → echo + exit 0), and
      (b) runs `direnv exec . check-jsonschema --builtin-schema vendor.dependabot .github/dependabot.yml`
      (skip with a message only if the file does not exist). Echo a "gha: clean." success line.
      Include a doc comment above the recipe in the existing style.

- [x] 003: Fold `lint-gha` into the `lint` umbrella recipe in `justfile`
      (`lint: lint-swift lint-py lint-sh lint-nix lint-yaml lint-gha l10n-check`) and update
      any adjacent comment if needed. Run `just lint-gha` on the current tree to surface the
      baseline (feeds task 004).

- [x] 004: Fix any pre-existing violations actionlint / check-jsonschema report in the
      current `.github/` files (expected zero or trivial — e.g. shellcheck findings inside
      `run:` blocks or schema nits in `dependabot.yml`). Scope strictly to making the
      baseline clean; no behavioral workflow changes. If the baseline is already clean,
      record that in the story log and check this task off with no diff.

- [x] 005: Add two steps to the existing blocking job in `.github/workflows/lint.yml`,
      mirroring the current step pattern: an `actionlint` step using
      `nix develop .#lint --command bash -c` with the `git ls-files` file-collection idiom
      (same shape as the yamllint step), and a `check-jsonschema (dependabot)` step running
      `nix develop .#lint --command check-jsonschema --builtin-schema vendor.dependabot .github/dependabot.yml`.
      No new third-party actions, no ad-hoc installs; keep the edited file
      yamllint- and actionlint-clean (it now lints itself).

- [x] 006: Verify all acceptance criteria end-to-end on the worktree:
      `nix develop .#lint --command actionlint --version` and
      `nix develop .#lint --command check-jsonschema --version` succeed; `just lint-gha`
      passes and demonstrably fails on a violation (temporary scratch check, not committed);
      full `just lint` passes on the current tree; `git status` shows changes only in
      `flake.nix`, `justfile`, `.github/workflows/lint.yml` (plus any task-004 baseline
      fixes in `.github/`), and `flake.lock` is unchanged.
