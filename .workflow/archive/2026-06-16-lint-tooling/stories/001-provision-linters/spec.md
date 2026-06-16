# Story 001 — Provision linters in the flake + base configs + just recipes

## Goal
Make every linter available through the Nix flake dev shell (no hardcoded `/nix` paths) and expose
`just` recipes that run them via `direnv exec .`. Add idiomatic config files. This story stands alone:
after it, `just lint` exists and runs, even if violations remain (those are fixed in story 002).

## Acceptance criteria
- `flake.nix` dev shell adds: `swiftlint`, `ruff`, `nixfmt` (nixfmt-rfc-style), `yamllint`.
  `swiftformat` and `shellcheck` already present.
- Config files added and idiomatic:
  - `.swiftlint.yml` — sensible opt-in/disabled rules; excludes generated/test dirs as appropriate.
  - `.swiftformat` — rules consistent with the codebase.
  - `pyproject.toml` (or `ruff.toml`) — Ruff lint + format config targeting `scripts/`.
  - `.yamllint` — relaxed-but-meaningful ruleset (line length, etc.).
  - nixfmt needs no config.
- `justfile` recipes: `lint` (runs all), `lint-swift`, `lint-py`, `lint-nix`, `lint-yaml`,
  and existing `lint-sh` folded in. All invoke tools through `direnv exec .`.
- `just lint` runs end-to-end (may report violations; exit code handled in story 002/CI).

## Notes
- No hardcoded `/nix` paths; use `direnv exec .` like `lint-sh`.
