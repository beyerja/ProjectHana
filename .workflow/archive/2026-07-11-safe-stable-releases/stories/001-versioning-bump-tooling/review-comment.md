<!-- independent-review -->
## Independent review — round 1

**Verdict: APPROVED** — no blocking findings.

### What was reviewed
Deep multi-angle review of the full diff (line-by-line scan, removed-behavior audit, cross-file tracing, reuse/simplification/efficiency/conventions passes), plus empirical verification in a clean worktree checkout of the branch:

- `scripts/test-bump-version.sh` — 27/27 pass.
- `just lint-sh` (shellcheck) and `just lint-py` (ruff check + format) — green including the new files.
- **Live end-to-end run of `just bump patch`** — produced exactly the expected clean diff: the two version values in `project.yml` (`1.0.0 -> 1.0.1`, build `1 -> 2`) plus only the corresponding regenerated `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` lines in the committed `Hanahuac.xcodeproj/project.pbxproj` (no unrelated xcodegen drift, which also proves the committed pbxproj in this PR is in sync with xcodegen output). Reverted after verification.

### Acceptance criteria
- `project.yml` single source of truth, no version value introduced elsewhere — met (grep confirms only project.yml + regenerated pbxproj carry the values).
- `MARKETING_VERSION` normalized `1.0` -> `1.0.0` — met, in both project.yml and both pbxproj build configs; no runtime consumer of the version string is affected.
- Committed bump script exposed as `just bump <major|minor|patch>`, bumps semver part (lower parts reset), build +1, regenerates the Xcode project, validates inputs (invalid part / non-semver / non-integer build / missing or duplicated keys) with clear stderr messages and non-zero exit — met, exercised by the test suite and live run.
- Clean reviewable diff from `just bump patch` — met (verified live, see above).
- Tagging convention (`v<MAJOR>.<MINOR>.<PATCH>` annotated tags on main only; manual edits discouraged) stated in the script header and justfile recipe comment — met.
- shellcheck / ruff green; lint gate untouched (`ci.yml`, `lint.yml`, `secret-scan.yml` unmodified) — met.

### Findings
One non-blocking inline nit posted: quote `'{{part}}'` in the `bump` recipe for consistency with the other parameterized justfile recipes (unquoted interpolation lets the shell expand the argument before argparse validates it). Does not block approval; fine to fold into this PR or a follow-up.

*The formal `code-owner-review` gate check is posted by the separate code-owner-review agent.*
