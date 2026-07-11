<!-- code-owner-review -->
## Code-owner review — round 1

**Verdict: APPROVED** — the required `code-owner-review` status check has been posted with conclusion `success` on head `c49ca79` (verified via read-back: `app_id: 4144849`).

### Independent verification (second cold-context pass, diff reviewed directly)
- `scripts/bump-version.py`: bump logic correct (lower semver parts reset, build +1), strict validation of part / semver / build-number / missing-or-duplicate keys with clear stderr + non-zero exit; span-based replacement preserves every other byte of `project.yml`; regeneration via `direnv exec . xcodegen generate` (no hardcoded nix paths).
- Wiring is reachable: `just bump <part>` recipe (production call site) and `just test-version-scripts`; the test script correctly follows the pre-existing `scripts/test-lib.sh` harness contract.
- `MARKETING_VERSION` normalized `1.0` → `1.0.0` consistently in `project.yml` and both regenerated pbxproj configs; no version value introduced anywhere else.
- Constraints held: `ci.yml` / `lint.yml` / `secret-scan.yml` untouched; tagging convention (`v<MAJOR>.<MINOR>.<PATCH>` annotated tags on `main` only, manual edits discouraged) documented in the script header and justfile comment.
- First reviewer's nit (unquoted `{{part}}` in the `bump` recipe): agreed non-blocking — argparse `choices` rejects invalid parts; fine as a follow-up.
- CI on head `c49ca79`: all 4 required checks completed green; no re-trigger needed.
