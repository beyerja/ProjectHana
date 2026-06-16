## Tasks
- [ ] 001: Add a single justfile variable `wt` (worktree/slug id) defaulting from env `HANA_FEATURE_SLUG`, empty otherwise; derive per-worktree DerivedData, /tmp output, and simulator-name suffixes from it.
- [ ] 002: Parameterize `test`, `build-sim`/`install-sim`/`boot-sim`/`launch-sim`/`screenshot-sim`, and `build-mac`/`install` to use the isolated paths/destination, with empty-default fallback to today's exact behavior.
- [ ] 003: Run `just lint-sh` to confirm bash recipes remain shellcheck-clean.
