<!-- code-owner-review -->
## Code-owner review — round 1: APPROVED

Independent second-eye verification of head `ae00827` (diff reviewed directly; independent-review round-1 findings read as input, verdict formed independently).

**Gate: `code-owner-review` status check posted with conclusion `success` on `ae00827`** (read-back verified: `app_id 4144849`).

### Independent verification highlights
- All 6 acceptance criteria traced as met: Keep-a-Changelog `CHANGELOG.md` with `[Unreleased]` + release-procedure header; `check-changelog.sh` (explicit or `project.yml`-derived version, anchored dot-escaped heading match — `1.0.0` cannot false-match `## [1.0.0-rc.1]`, `[Unreleased]` never satisfies); `check-tag-version.sh` (v-prefix + strict base + valid optional prerelease, `v1.0.0-` / `v1.0.0-rc..1` rejected); positive AND negative paths tested with real teeth (non-zero exit + stderr asserted, no skip/degradation); no per-PR blocking workflow touched; CI (Build & Test, Lint, gitleaks) green on head.
- First reviewer's non-blocking note (duplicated `read_marketing_version` helper) confirmed non-blocking: the spec requires standalone scripts.
- Only nit found: the tag regex tolerates leading zeros in the numeric base (`v01.0.0`), but such a tag cannot pass the `MARKETING_VERSION` equality anyway — non-blocking.

Note: PR base is currently BEHIND main; the gate check is SHA-bound, so any `update-branch` (new head SHA) requires re-posting the check on the new head.
