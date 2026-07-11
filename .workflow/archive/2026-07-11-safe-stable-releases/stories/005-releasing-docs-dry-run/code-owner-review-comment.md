<!-- code-owner-review -->
## Code-owner review (second independent pass)

**Verdict: APPROVED** — `code-owner-review` check posted `success` on head `da5487c`
(read-back confirmed: app id 4144849).

Independent re-verification of the docs-only diff (`docs/releasing.md` +223, `README.md` +3),
performed directly (not via /code-review):

- **release.yml parity**: gates (a)–(g) documented exactly as implemented, including gate (a)'s
  skipped-with-explanation dry-run branch, `dry_run` default `true`, the `release-artifacts`
  upload set, the publish job's real-tag-only condition, the three `APP_STORE_CONNECT_*` secret
  names, and the `APPSTORE_UPLOAD_ENABLED` repo variable — all verbatim matches.
- **justfile parity**: `bump` → `scripts/bump-version.py`; `archive` → unsigned generic-iOS
  `.xcarchive` + `scripts/package-ipa.sh`; `release-check` = 6 steps + optional tag arg with skip
  note; `test-mac` local UI-test skip deviation documented accurately.
- **project.yml**: `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` present; no
  `DEVELOPMENT_TEAM`/`CODE_SIGN_STYLE` — switch-on section premise accurate.
- **Dry-run proof re-verified via API**: run 29126126066 is `workflow_dispatch` on `main` of
  `release.yml`, conclusion `success`; recorded in the PR description per the spec.
- **Spec ACs**: all six acceptance criteria covered; per-PR blocking CI files untouched.
- **CI on head**: Build & Test, gitleaks, Lint, change-detect all present and green — no
  self-heal re-trigger needed.

Concur with the `independent-review` round-1 APPROVED verdict; no blocking findings of my own.
