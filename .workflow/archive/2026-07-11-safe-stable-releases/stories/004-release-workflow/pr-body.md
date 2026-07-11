# Story 004 — Release CI workflow

## Goal

Deliver `.github/workflows/release.yml`: a gated, unsigned, artifact-producing release pipeline
triggered by `v*` tag pushes and `workflow_dispatch` (with a `dry_run` input), which enforces the
full quality bar, produces inspectable unsigned artifacts with SHA-256 checksums, publishes a
GitHub Release with CHANGELOG-derived notes, and carries cleanly-skipping App Store Connect /
TestFlight placeholder steps — all without touching the per-PR blocking check set.

## Summary of changes

- **`.github/workflows/release.yml`** — new two-job workflow:
  - Triggers: `v*` tag push + `workflow_dispatch` with `dry_run`; **no** `pull_request` trigger.
    Concurrency group per ref (`cancel-in-progress: false`), runner `macos-15`, Nix via
    `cachix/install-nix-action@v31` (mirroring `lint.yml`).
  - **Build/gate job** enforces, in order, each failing the run on violation:
    (a) tag↔`project.yml` version match via `scripts/check-tag-version.sh` (skipped in dry-run),
    (b) `CHANGELOG.md` section present via `scripts/check-changelog.sh`,
    (c) full lint suite,
    (d) xcodegen generate + full `xcodebuild test` on Mac Catalyst (mirroring `ci.yml` verbatim),
    (e) `generate-geo-packs.py --check`,
    (f) `verify-odr-packs.sh`,
    (g) Release-config build + `verify-base-only-bundle.sh`.
  - Produces an **unsigned** Release-configuration `.xcarchive` (zipped) plus an unsigned `.ipa`
    (via the story-003-proven `just archive` / `ditto --norsrc` path — no Catalyst fallback needed),
    with a `SHA256SUMS.txt` checksum file, uploaded as artifacts
    (`actions/upload-artifact@v7` / `actions/download-artifact@v8`).
  - **Publish job** holds the workflow's *only* `contents: write` grant and creates the GitHub
    Release for real tags via `gh release create --verify-tag --notes-file <changelog-section>
    --generate-notes`, attaching the zipped `.xcarchive`, `.ipa`, and checksum file; prerelease
    tags (e.g. `v1.1.0-rc.1`) get `--prerelease`. Dry-run performs everything except tag
    enforcement and Release publication.
  - **App Store Connect / TestFlight upload steps** exist as clearly-labeled, disabled
    placeholders gated on `vars.APPSTORE_UPLOAD_ENABLED == 'true'` AND the
    `APP_STORE_CONNECT_*` secrets; with no account configured they skip with an explanatory
    log line and the workflow succeeds end-to-end. Nothing requires signing or Apple credentials.
- **`scripts/extract-changelog-section.sh`** — extracts a version's CHANGELOG section for the
  Release body; covered by **`scripts/test-extract-changelog-section.sh`** (22 assertions),
  wired into `just test-release-scripts` (58 total assertions, all green).
- **Zero changes to the per-PR blocking check set**: `ci.yml`, `lint.yml`, and `secret-scan.yml`
  are byte-for-byte untouched (empty diff vs `origin/main`); all new automation runs only on tag
  push or `workflow_dispatch`.

## Action version verification (empirical, per story constraint)

Verified at implementation time via `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`
and a grep over the repo's existing workflow pins — **not** assumed from training data:

| Action | Marketplace latest | Pin used | Note |
| --- | --- | --- | --- |
| `actions/checkout` | v7.0.0 | `@v7` | matches repo-wide pin (all 7 existing workflows) |
| `cachix/install-nix-action` | v31.10.6 | `@v31` | matches `lint.yml` pin |
| `actions/upload-artifact` | v7.0.1 | `@v7` | first use in this repo |
| `actions/download-artifact` | v8.0.1 | `@v8` | first use in this repo |

`gh release create --notes-file <f> --generate-notes` combination also verified empirically:
the CLI accepts both flags together (flag test reached the API with no conflict error), and the
REST "Create a release" docs (apiVersion 2022-11-28) confirm a specified `body` is **pre-pended**
to the automatically generated notes — yielding exactly the spec'd Release body (CHANGELOG
section first, generated notes appended), with no fallback concatenation needed.

## Test plan

- [x] `just lint` fully green (yamllint + actionlint over `release.yml`; shellcheck over both new scripts)
- [x] `just test-release-scripts` green — 58 assertions incl. 22 new for `extract-changelog-section.sh`
- [x] Rehearsal against real repo state: `check-tag-version.sh v1.0.0` OK, `check-changelog.sh` OK,
      `extract-changelog-section.sh 1.0.0` prints the 1.0.0 body
- [x] `ci.yml` / `lint.yml` / `secret-scan.yml` empty diff vs `origin/main`
- [ ] CI Build & Test green on this PR (no Swift/source changes; app suite covered by PR CI)
- [ ] Post-merge: `workflow_dispatch` dry-run of `release.yml` end-to-end

🤖 Generated with [Claude Code](https://claude.com/claude-code)
