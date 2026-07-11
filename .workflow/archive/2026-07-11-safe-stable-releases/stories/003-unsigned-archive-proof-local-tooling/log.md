# Story 003 — unsigned-archive-proof-local-tooling — log

- 2026-07-04: story-workflow started. No prior PR, no prior log — fresh run.
- 2026-07-04: Worktree was on stale story/002 branch; synced by creating
  story/safe-stable-releases/003-unsigned-archive-proof-local-tooling from origin/main (e058266).
- 2026-07-04: Spawning break-tasks.
- 2026-07-04 break-tasks: DONE, 7 tasks.
- 2026-07-05 implement-story: EMPIRICAL PROOF OUTCOME (binding input for stories 004/005):
  - **Unsigned iOS device archive: PROVEN — `** ARCHIVE SUCCEEDED **`.** No Catalyst fallback
    needed; no signing or Apple credentials required. Exact proven command (run from the repo
    root; throwaway paths shown, `just archive` uses per-worktree `_sfx` paths):
    ```
    xcodebuild archive \
      -project Hanahuac.xcodeproj \
      -scheme Hanahuac \
      -configuration Release \
      -destination 'generic/platform=iOS' \
      -archivePath /tmp/Hanahuac-archive-proof-safe-stable-releases/Hanahuac.xcarchive \
      -derivedDataPath /tmp/Hanahuac-archive-proof-safe-stable-releases/dd \
      CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
    ```
    Archive produced `Products/Applications/Hanahuac.app` (~12 MB .xcarchive, incl. dSYM).
  - **Unsigned `.ipa` packaging: FEASIBLE — proven.** Plain `ditto` zip of a `Payload/` dir,
    no signing step. Exact proven commands:
    ```
    ditto <archive>/Products/Applications/Hanahuac.app <stage>/Payload/Hanahuac.app
    ditto -c -k --norsrc --keepParent <stage>/Payload <out>/Hanahuac.ipa
    ```
    `--norsrc` matters: without it ditto embeds AppleDouble `._*` metadata files (and
    `--sequesterRsrc` adds a `__MACOSX/` tree) into the zip; with it `unzip -l` shows a clean
    `Payload/Hanahuac.app/...` layout (23 files, binary + resources present).
  - Note: the .ipa is UNSIGNED — installable evidence artifact only (sideload/re-sign later);
    a signed device archive activates once the Apple Developer account exists. Stories 004/005
    must consume this outcome: 004 can build the release workflow on the unsigned device
    archive + unsigned .ipa path (no Catalyst fallback), 005 documents it in docs/releasing.md.
- 2026-07-05 implement-story: tooling delivered.
  - `just archive`: unsigned Release device .xcarchive + unsigned .ipa (scripts/package-ipa.sh),
    per-worktree isolation via `archive_dd`/`archive_out` (+ `mac_release_dd` for release-check);
    echoes both artifact paths. Ran end-to-end: ARCHIVE SUCCEEDED, ipa packaged + verified.
  - `just release-check [tag]`: 6-step local release quality bar (lint, Catalyst test suite,
    geo-packs-check, verify-odr-packs, Release Catalyst build + verify-base-only-bundle,
    check-changelog [+ check-tag-version when a tag is given, explicit skip note otherwise]).
    Ran end-to-end BOTH with `v1.0.0` and without a tag: ALL CHECKS PASSED.
  - EMPIRICAL finding (also relevant to 004/005 docs): executing HanahuacUITests against a
    Catalyst app locally fails deterministically ("The test runner hung before establishing
    connection", 2x reproduced; 532 unit tests green) — the runner needs UI-automation
    permissions this environment doesn't grant. Matches the project's known
    CI-runs-Catalyst-UITests convention. `test-mac` therefore COMPILES all test bundles but
    passes `-skip-testing:HanahuacUITests` with an explicit note; UI tests execute on Catalyst
    in CI (required Build & Test check) and locally via `just ui-walkthrough` (simulator).
  - CHANGELOG.md: moved the [Unreleased] content under `## [1.0.0] - 2026-07-05` (per the
    changelog's own release procedure; check-changelog derives 1.0.0 from project.yml and
    requires the section — release-check step 6 fails otherwise). Fresh empty [Unreleased] kept.
  - `just lint` green (incl. shellcheck over the new tracked scripts/package-ipa.sh).
- 2026-07-05 implement-story: DONE — all 7 tasks completed (proof 001-003, `just archive` 004,
  `just release-check` 005, end-to-end runs 006, lint 007). Commit 079bed7 (justfile,
  scripts/package-ipa.sh, CHANGELOG.md). Issues: local Catalyst UITest runner hang (adopted
  `-skip-testing:HanahuacUITests` locally, CI still executes them); CHANGELOG needed its
  `## [1.0.0]` section for check-changelog to pass; .workflow/stories is gitignored so story
  artifacts are not committed. Not pushed — parent workflow owns push/PR.
- 2026-07-05 create-pr: rebased onto origin/main (clean, no conflicts), pushed branch, opened
  PR #228 — https://github.com/beyerja/ProjectHana/pull/228 (base: main).
- 2026-07-05 create-pr: DONE — https://github.com/beyerja/ProjectHana/pull/228
- 2026-07-05 independent-review: APPROVED — all ACs verified (empirical proof recorded first,
  archive/release-check correct, workflows untouched); 2 non-blocking inline nits (inert
  grep -v BRE filter in test-mac; CHANGELOG 1.0.0 date may need refresh at tag time).
- 2026-07-05 code-owner-review: APPROVED — independent re-verification of PR #228 (direct diff
  read, no /code-review): all ACs met (proof-first log entry, `just archive` = proven command
  with per-worktree paths + .ipa via package-ipa.sh, `just release-check` full quality bar,
  no signing/credentials, protected workflows untouched, shellcheck-clean). Both prior nits
  judged non-blocking; local `-skip-testing:HanahuacUITests` acceptable (CI still executes
  UI tests). CI green 4/4 on head 3c8f6e1. Gate check `code-owner-review` posted with
  conclusion=success on 3c8f6e14816ea0af15a59bb0e10ccdf3fcd7bae2; read-back confirmed
  app_id 4144849 (hanahuac-review-bot). Summary comment posted (issuecomment-4885034483).
- 2026-07-05 merge-pr: PR #228 squash-merged (mergeStateStatus CLEAN on gated head 3c8f6e1);
  merge commit 3b555cad81768f1b6a6238fd57671e2de5a0a19f, remote branch deleted. Worktree
  switched to main and fast-forwarded (origin/main advanced to aa57b65 by a parallel merge);
  local story branch deleted. Primary checkout left untouched (busy on a parallel feature's
  chore branch).
- 2026-07-05 merge-pr: DONE
- 2026-07-05 verify-story: DONE — all acceptance criteria verified against merged main
  (worktree on main, up to date with origin/main at aa57b65, story merge 3b555ca):
  1. Empirical proof recorded FIRST in this log (2026-07-05 entry precedes tooling entry):
     unsigned device archive PROVEN (`generic/platform=iOS`, CODE_SIGNING_ALLOWED=NO,
     ARCHIVE SUCCEEDED) — criterion met.
  2. Fallback criterion N/A: device archive proven, log explicitly says no Catalyst
     fallback needed.
  3. `just archive` re-run on main: ARCHIVE SUCCEEDED; per-worktree paths via
     archive_dd/archive_out (+ _sfx from HANA_FEATURE_SLUG); both .xcarchive and .ipa
     paths emitted.
  4. .ipa feasibility PROVEN: scripts/package-ipa.sh produced /tmp/Hanahuac-archive/
     Hanahuac.ipa; `unzip -l` shows clean Payload/Hanahuac.app/... (23 files, binary +
     resources, no AppleDouble/__MACOSX entries).
  5. `just release-check v1.0.0` re-run on main: ALL CHECKS PASSED — lint suite, Catalyst
     test suite (TEST SUCCEEDED; HanahuacUITests compiled, execution skipped locally per
     documented convention), geo-packs-check, verify-odr-packs, Release build +
     verify-base-only-bundle (PASS), check-changelog OK + check-tag-version OK.
  6. No signing/credentials anywhere: all xcodebuild invocations use CODE_SIGN_IDENTITY="-",
     CODE_SIGNING_REQUIRED=NO, CODE_SIGNING_ALLOWED=NO; package-ipa.sh is a plain ditto zip.
  7. Lint gate green incl. shellcheck over scripts/package-ipa.sh (20 scripts, all passed).
  Constraint check: merge commit 3b555ca touched only CHANGELOG.md, justfile,
  scripts/package-ipa.sh — ci.yml/lint.yml/secret-scan.yml untouched. No Hanahuac/Views/**
  files changed, so no visual verification required (pure tooling story).
