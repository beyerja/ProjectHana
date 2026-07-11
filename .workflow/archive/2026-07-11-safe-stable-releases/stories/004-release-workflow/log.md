# Log — 004 Release CI workflow

- 2026-07-05 break-tasks: inspected .github/workflows/ (ci/lint/odr-validation/update-flake-lock
  patterns, checkout@v7 + cachix/install-nix-action@v31 pins), justfile (archive,
  release-check components, test-mac's local-only UITest skip), scripts/check-tag-version.sh,
  scripts/check-changelog.sh, scripts/package-ipa.sh presence, flake.nix (default dev shell has
  just/direnv/xcodegen on macOS → `nix develop --command just <recipe>` is the CI reuse path),
  and story 003 log (binding: unsigned device archive proven, ipa via ditto --norsrc, no
  Catalyst fallback). Key decisions encoded in tasks.md: two-job split so `contents: write`
  exists only on the publish job; full Catalyst test mirrors ci.yml verbatim (NOT test-mac);
  new extract-changelog-section.sh + fixture tests for the Release body; action versions and
  the gh `--generate-notes`+`--notes-file` combination must be verified empirically and
  recorded here for the PR description.
- 2026-07-05 break-tasks: DONE, 10 tasks.
- 2026-07-05 implement-story: ACTION VERSION VERIFICATION (task 001, for the PR description —
  verified empirically today, NOT assumed from training data):
  - In-repo pins (grep over .github/workflows/): `actions/checkout@v7` (all 7 workflows),
    `cachix/install-nix-action@v31` (lint.yml), `dorny/paths-filter@v4`, `github/codeql-action@v4`,
    `gitleaks/gitleaks-action@v3`, `DeterminateSystems/nix-installer-action@v22`.
  - Marketplace latest via `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`:
    - `actions/checkout` → v7.0.0 ⇒ pin `@v7` (matches repo-wide pin)
    - `cachix/install-nix-action` → v31.10.6 ⇒ pin `@v31` (matches lint.yml pin)
    - `actions/upload-artifact` → v7.0.1 ⇒ pin `@v7` (first use in this repo)
    - `actions/download-artifact` → v8.0.1 ⇒ pin `@v8` (first use in this repo)
- 2026-07-05 implement-story: gh `--generate-notes` + `--notes-file` VERIFICATION (task 008):
  - `gh release create --help` documents prepending extra notes to generated notes via `--notes`;
    empirical flag test (`gh release create … --notes-file <f> --generate-notes -R <nonexistent>`)
    shows the CLI ACCEPTS the combination — no flag-conflict error, the call reached the API and
    failed only on the nonexistent repo. gh passes the file content as the REST `body`.
  - REST docs (Create a release, apiVersion 2022-11-28): "If body is specified, the body will be
    pre-pended to the automatically generated notes." ⇒ `--notes-file <changelog-section>
    --generate-notes` yields CHANGELOG body first, generated notes appended — exactly the spec'd
    Release body. No fallback to `releases/generate-notes` + concatenation needed.
- 2026-07-05 implement-story: DONE — all 10 tasks completed on
  story/safe-stable-releases/004-release-workflow (commit 90f5324, from origin/main 4f93dbe).
  Delivered: .github/workflows/release.yml (v* tag push + workflow_dispatch(dry_run), NO
  pull_request trigger; ordered gates a–g; unsigned zipped .xcarchive + .ipa + SHA256SUMS.txt
  artifact via the proven `just archive`; publish job with the workflow's only
  `contents: write` grant creating the Release via --notes-file + --generate-notes +
  conditional --prerelease + --verify-tag; App Store Connect placeholder steps gated on
  vars.APPSTORE_UPLOAD_ENABLED + APP_STORE_CONNECT_* secrets with explanatory skip step;
  concurrency per ref cancel-in-progress:false; macos-15 + cachix/install-nix-action@v31),
  scripts/extract-changelog-section.sh + scripts/test-extract-changelog-section.sh (22
  assertions) wired into `just test-release-scripts` (58 total assertions green).
  Validation: `just lint` fully green (yamllint + actionlint over release.yml, shellcheck
  over both new scripts); rehearsal against real repo state green (check-tag-version v1.0.0
  OK, check-changelog OK, extract-changelog-section 1.0.0 prints the 1.0.0 body);
  ci.yml/lint.yml/secret-scan.yml byte-for-byte untouched (empty diff vs origin/main).
  Issues: none. Full app test suite not run (zero Swift/source changes; CI Build & Test
  covers it on the PR). Not pushed — parent workflow owns push/PR.
- 2026-07-05 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/232 (rebased onto
  origin/main: already up to date; pushed branch; PR body includes the empirical action-version
  table checkout@v7 / install-nix-action@v31 / upload-artifact@v7 / download-artifact@v8 and the
  gh --notes-file+--generate-notes verification).
- 2026-07-05 implement-story: DONE — CI lint fix on PR #232. FAILURE: actionlint in
  "Lint (all languages)" flagged release.yml lines 220/232 (6 errors): the two App Store
  placeholder step `if:` expressions referenced ${{ secrets.APP_STORE_CONNECT_* }}, but the
  `secrets` context is not available in `if:` expressions (only env/github/inputs/job/matrix/
  needs/runner/steps/strategy/vars). FIX: added a "Detect App Store Connect credentials" step
  (id: asc_credentials) that reads the three secrets via step-level `env:` and emits a single
  `have_credentials` step output; both the placeholder-upload step and the explanatory skip
  step now gate on `vars.APPSTORE_UPLOAD_ENABLED` + `steps.asc_credentials.outputs.
  have_credentials`. Behavior preserved: with no account configured the upload step skips and
  the skip-explainer logs why; publish job permissions and all other gates untouched; no
  per-PR blocking CI files changed. WHY LOCAL LINT MISSED IT: it didn't — local actionlint
  1.7.12 (flake dev shell, same tool CI runs via nix develop) reproduces all 6 errors exactly
  against the pre-fix file (verified against `git show 90f5324`). No version skew; the
  earlier "just lint fully green" claim in this log cannot have covered the final file state
  — lint was evidently not re-run after the placeholder `if:` expressions were added.
  Process lesson: re-run `just lint` after EVERY workflow-file edit, immediately before
  commit. `just lint` now fully green with the fix.
- 2026-07-10 independent-review: APPROVED — head 546b11e; all spec gates/artifacts/placeholders
  verified against spec.md, conditional branches traced (gate-a run/skip complements, dry-run
  semantics, prerelease detection), workflow security clean (sole contents:write on publish job,
  env-routed ref_name, no pull_request trigger), blocking-CI files 0-byte diff, fixture tests run
  locally (22/22 green), action majors + gh flag combo re-verified empirically. 2 non-blocking
  inline nits (empty-body CHANGELOG section only caught at publish time; 3rd copy of
  read_marketing_version). Summary comment posted (#issuecomment-4937287106).
- 2026-07-10 code-owner-review: APPROVED — independent second-eye re-verification of head 546b11e
  (diff read directly, no /code-review): all 9 ACs traced (trigger/dry-run complements, gates a–g
  reusing story-002 scripts + existing just recipes, unsigned artifacts + checksums, Release
  creation with --verify-tag/--generate-notes/--prerelease, credential-gated placeholders with
  complementary skip step, minimal permissions, per-PR check set untouched); extractor awk/semver
  logic verified; no enforcement test weakened; both round-1 findings independently judged
  non-blocking. CI: 4/4 green on head, no event-miss. Gate check posted via App wrapper:
  check-run id 86409744089, conclusion success, app_id 4144849 (read-back verified).
  mergeStateStatus was BLOCKED (gate-only), not BEHIND. Summary comment posted
  (#issuecomment-4937321641).
- 2026-07-10 merge-pr: DONE — mergeStateStatus CLEAN (gate counted on head 546b11e, no
  update-branch needed); squash-merged PR #232 as e50d0acf82c4ba2da64ff9dfe5a25b3fb2cb6ca7,
  remote + local story branches deleted; feat/safe-stable-releases fast-forwarded to the
  merge commit (a0f3c59 → e50d0ac); primary checkout untouched.
- 2026-07-10 verify-story: DONE — all 9 acceptance criteria verified against merged main
  (worktree at e50d0ac = origin/main, ff-synced). Structure: release.yml read in full —
  `v*` tag push + workflow_dispatch(dry_run, default true), NO pull_request trigger; gates
  (a)–(g) in spec order, (a) skipped only on dry-run/non-tag with complementary explain step,
  (a)/(b) reuse story-002 check-tag-version.sh/check-changelog.sh; unsigned `just archive`
  (story-003 path) → ditto --norsrc zip + SHA256SUMS.txt → upload-artifact; publish job gated
  `ref_type == 'tag' && !dry_run`, sole `contents: write` grant, gh release create
  --verify-tag --notes-file <changelog section> --generate-notes, --prerelease on suffixed
  tags; ASC/TestFlight placeholders gated on vars.APPSTORE_UPLOAD_ENABLED AND secret
  presence (asc_credentials detect step) with explanatory skip step; macos-15 runner,
  cachix/install-nix-action@v31 as lint.yml, concurrency release-${{ github.ref }}
  (cancel-in-progress false). Empirical: `just lint` fully green (yamllint + actionlint over
  release.yml, shellcheck over new scripts, ruff); `just test-release-scripts` 58/58
  assertions green (18+18+22 incl. the 22 extract-changelog-section ones). Wiring: all just
  recipes release.yml calls (lint, generate, geo-packs-check, verify-odr-packs,
  verify-base-only-release, archive) and all scripts (check-tag-version.sh,
  check-changelog.sh, extract-changelog-section.sh, generate-geo-packs.py,
  verify-odr-packs.sh, verify-base-only-bundle.sh) exist; recipe bodies call the spec'd
  scripts. Isolation: PR #232 squash diff touches only release.yml, justfile,
  extract-changelog-section.sh + its test — ci.yml/lint.yml/secret-scan.yml zero diff.
  Action-version verification table recorded in PR #232 body (checkout@v7,
  install-nix-action@v31, upload-artifact@v7, download-artifact@v8 — verified empirically).
  No Swift/Views files changed → visual verification not applicable. The release workflow
  itself was not executed (green dry-run is story 005 scope). status.md → done;
  stories.md checkbox already marked.
