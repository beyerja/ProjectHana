# Tasks — 005 releasing docs + green dry-run

Ordering note: task 001 dispatches the dry-run FIRST because the run takes 30–60 min on a
macOS runner; the docs tasks (002–006) are written while it executes, and task 007 blocks on
its completion. All commands must be allowlistable shapes (no `cd &&`, no heredocs, no
`$(…)` payloads, no poll loops).

## Tasks
- [x] 001: Dispatch the release.yml dry-run on `main` (main already contains release.yml —
      story 004 merged as e50d0ac): `gh -R beyerja/ProjectHana workflow run release.yml
      --ref main -f dry_run=true`. Then a single `sleep 15`, then find the run id with
      `gh -R beyerja/ProjectHana run list --workflow=release.yml --limit 1` and append the
      run id + URL to `<story-dir>/log.md` (via Edit/Write, never `cat >>`). Do NOT wait on
      it yet — that is task 007.
- [x] 002: Create `docs/releasing.md` (lowercase, matching the existing `docs/` layout) with
      a title, a short intro, and the **Versioning** section: semver `MARKETING_VERSION` +
      integer `CURRENT_PROJECT_VERSION` (both in `project.yml` targets block — the single
      source of truth; manual edits discouraged), the bump procedure `just bump
      <major|minor|patch>` (wraps `scripts/bump-version.py`, which also regenerates the
      Xcode project), and the tags-only release model (annotated `v<MAJOR>.<MINOR>.<PATCH>`
      tags on `main` only; semver prerelease suffixes like `v1.1.0-rc.1` allowed and marked
      prerelease by the workflow). Markdown in `docs/` is not covered by `just lint` — no
      lint task needed for prose alone.
- [x] 003: Add the **step-by-step release runbook** section to `docs/releasing.md`: (1) open
      a bump PR — `just bump …` + finalize the CHANGELOG.md `## [X.Y.Z]` section
      (Keep-a-Changelog; `scripts/check-changelog.sh` is the enforcement) — (2) merge via
      the normal gate (per-PR CI + SHA-bound `code-owner-review` status check; nothing
      bypasses it; note `gh pr update-branch` re-blocks and needs the gate re-posted on the
      new SHA), (3) create + push the annotated tag `git tag -a vX.Y.Z -m …` /
      `git push origin vX.Y.Z` on the merge commit, (4) the tag push triggers
      `.github/workflows/release.yml` (also manually dispatchable with `dry_run`), (5)
      verify the GitHub Release: title = tag, body = CHANGELOG section + generated notes,
      assets `Hanahuac.xcarchive.zip`, `Hanahuac.ipa`, `SHA256SUMS.txt` (verify checksums).
- [x] 004: Add the **quality gates** section to `docs/releasing.md`: table/list of release.yml
      gates (a)–(g) — tag↔version consistency (`scripts/check-tag-version.sh`; enforced only
      on real tag refs, skipped with an explanation on dry runs), CHANGELOG section present
      (`scripts/check-changelog.sh`), full lint suite (`just lint`), full Catalyst test suite
      exactly as ci.yml (UI tests EXECUTE in CI), geo packs up to date, ODR pack integrity,
      Release build + base-only bundle validation — with one sentence each on what it
      protects. Document the local equivalents `just release-check [vX.Y.Z]` (6 steps) and
      `just archive`, the recorded story-003 empirical outcome (unsigned iOS DEVICE Release
      archive PROVEN — no signing identity, provisioning profile, or Apple credentials
      needed; unsigned `.ipa` produced by `scripts/package-ipa.sh`, an installable-evidence
      artifact for sideload/re-sign), and the documented deviation: `just test-mac` locally
      COMPILES HanahuacUITests but skips execution (deterministic local Catalyst XCUITest
      runner hang without UI-automation permissions, 2x reproduced in story 003) while CI
      runs them on Catalyst — plus `just ui-walkthrough` as the local simulator UI path.
- [x] 005: Add the clearly-marked **"When the Apple Developer account exists"** section to
      `docs/releasing.md`: exact secret names `APP_STORE_CONNECT_KEY_ID`,
      `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY` (the `.p8` content) —
      noting secret creation is a HUMAN action per project convention; the repo variable
      `APPSTORE_UPLOAD_ENABLED` flip to `'true'`; the `project.yml` signing settings to add
      (`DEVELOPMENT_TEAM: <team id>`, `CODE_SIGN_STYLE` — currently absent; builds are
      unsigned); the ExportOptions plist to add for `xcodebuild -exportArchive`; which
      release.yml placeholder steps go live (the `publish-release` job's credential-detection
      step + "Upload to App Store Connect / TestFlight (placeholder)" echo step become a real
      signed archive + export + upload); and the EXPLICIT note that the upload tooling
      (`xcodebuild -exportArchive` + `notarytool`/altool/Transporter vs. fastlane) must be
      re-verified against current Apple tooling at switch-on time, not assumed from this doc.
- [x] 006: Link `docs/releasing.md` from the README docs index (the existing `docs/…` bullet
      list around line 11) with a one-line description, matching the surrounding style.
- [x] 007: Wait for the dispatched dry-run: `gh -R beyerja/ProjectHana run watch <run-id>
      --exit-status` (blocking; expect 30–60 min — set the Bash timeout high, and if the
      watch times out at the 600000 ms tool cap, issue another single `run watch`, not a
      poll loop). REQUIRED GREEN. If it FAILS: pull the failing-step logs with
      `gh -R beyerja/ProjectHana run view <run-id> --log-failed`, diagnose, fix on the story
      branch (ZERO changes to ci.yml/lint.yml/secret-scan.yml; `just lint` must stay green),
      push the story branch, re-dispatch with `--ref story/safe-stable-releases/005-releasing-docs-dry-run`
      (workflow_dispatch needs the workflow file on the dispatched ref — the story branch
      carries the fix before merge), and watch again. Repeat until GREEN; a failing dry-run
      is fixed, never waived.
- [x] 008: Record the GREEN run URL + conclusion: append to `<story-dir>/log.md` (Edit tool)
      and add a short "First proven run" note with the run URL to `docs/releasing.md`. Flag
      in the log that the run URL must also appear in the PR description (create-pr step
      consumes this).
- [x] 009: Run `just -f <worktree>/justfile lint` to confirm the lint gate is green (docs
      markdown is unlinted, but any release.yml/script fix from task 007 must pass yamllint/
      actionlint/shellcheck/ruff), and confirm `git -C <worktree> status` shows only intended
      files (docs/releasing.md, README.md, story-dir files, plus any task-007 fix).
