<!-- independent-review -->
## Independent review — round 1

**Verdict: APPROVED** — no blocking findings.

Deep review (high effort, docs-only diff: `docs/releasing.md` +223, `README.md` +3). Every factual
claim in the runbook was verified against repo reality:

- **release.yml**: gates (a)–(g) match exactly, including gate (a)'s skipped-with-explanation
  dry-run branch, `dry_run` default `true`, the `release-artifacts` upload set
  (`Hanahuac.xcarchive.zip` / `Hanahuac.ipa` / `SHA256SUMS.txt`), and the publish job's
  real-tag-only condition. Secret names (`APP_STORE_CONNECT_KEY_ID` / `_ISSUER_ID` /
  `_PRIVATE_KEY`) and the `APPSTORE_UPLOAD_ENABLED` variable match the workflow verbatim.
- **justfile**: `bump`, `archive` (generic iOS device, unsigned, `scripts/package-ipa.sh`),
  `release-check` (6 steps + optional tag), `test-mac` deviation, and `ui-walkthrough` all match
  the documented behavior.
- **project.yml**: `MARKETING_VERSION: "1.0.0"` + `CURRENT_PROJECT_VERSION: "1"` present; no
  `DEVELOPMENT_TEAM`/`CODE_SIGN_STYLE` — the switch-on section's "currently absent" claim is
  accurate.
- **Scripts**: `bump-version.py` (reset lower parts, +1 build, byte-preserving rewrite, xcodegen
  regen) and `check-tag-version.sh` (vX.Y.Z base + optional prerelease vs `MARKETING_VERSION`)
  behave exactly as documented; `SHA256SUMS.txt` uses bare filenames so the documented
  `shasum -a 256 -c` verification works.
- **Dry-run proof**: run 29126126066 confirmed `conclusion: success`, `workflow_dispatch` on
  `main`; URL recorded in both the story log and the PR description (AC5).

All six acceptance criteria of story 005 are satisfied; constraints hold (`ci.yml`, `lint.yml`,
`secret-scan.yml` untouched). No inline findings were posted — the review surfaced none that
survived verification.

Note: the formal `code-owner-review` gate check is posted separately by the code-owner-review
agent; this comment is the independent-review verdict only.
