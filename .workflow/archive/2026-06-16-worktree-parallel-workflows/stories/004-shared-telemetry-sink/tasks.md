## Tasks
- [ ] 001: In agent-log.sh, resolve the telemetry sink to the PRIMARY checkout's .workflow/telemetry/ even when invoked from a worktree (via `git rev-parse --git-common-dir`), falling back to today's REPO_ROOT/.workflow/telemetry in a plain checkout.
- [ ] 002: Tag every start/end record with the feature slug (HANA_FEATURE_SLUG, default "" / "primary").
- [ ] 003: Update telemetry-summary.py to read the shared sink and preserve/surface per-feature attribution; keep the existing table + --history behavior correct.
- [ ] 004: Run `just lint-sh` and `just telemetry` to confirm both still work against the shared sink.
