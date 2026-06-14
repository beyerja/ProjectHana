# Story 002 — gitleaks secret-scanning workflow

## Goal

Add a secret-scanning workflow using gitleaks that runs on pull requests to `main` and
pushes to `main`, and fails the check when a secret is detected. gitleaks-action v3 is free
for public repositories.

## Acceptance Criteria

- [ ] `.github/workflows/secret-scan.yml` exists.
- [ ] Triggers: `pull_request` targeting `main` and `push` to `main`. (No path filter — a
      secret can be committed in any file type, so the scan must run on every relevant PR.)
- [ ] Uses `gitleaks/gitleaks-action@v3` (latest verified major as of 2026-06-14), pinned
      by major tag.
- [ ] Full git history is available to the scan (`actions/checkout` with `fetch-depth: 0`).
- [ ] The job fails (non-zero) when gitleaks finds a secret, so the PR check blocks merge.
- [ ] Runs on `ubuntu-latest` (gitleaks needs no macOS toolchain — keep it cheap/fast).
- [ ] No `GITLEAKS_LICENSE` is required (public repo → free); document that no secret/license
      env var is needed.
- [ ] No hardcoded `/nix/...` paths.
- [ ] Optional but recommended: a `.gitleaks.toml` config or rely on gitleaks defaults;
      if a config is added it must not be so permissive that it disables detection.

## Notes

- Independent of story 001 — touches only its own workflow file.
- Verify by intentionally testing detection logic locally if feasible, otherwise by the
  workflow running green (no real secrets) on its PR and confirming the config is correct.
