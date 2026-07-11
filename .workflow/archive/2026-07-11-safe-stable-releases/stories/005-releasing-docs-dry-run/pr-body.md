## Goal

Document the entire release process end-to-end in `docs/releasing.md` — including the exact
"switch-on" steps for when the Apple Developer account exists — and prove the delivered release
pipeline with a green `workflow_dispatch` dry-run of `release.yml` with no Apple credentials
present. This is the feature's first proven run and the human-facing contract for every future
release.

## Green dry-run (required proof)

- **Run:** https://github.com/beyerja/ProjectHana/actions/runs/29126126066
- **Conclusion:** success
- Dispatched via `workflow_dispatch` on `main`; gates job passed in 4m1s (553 tests executed
  including UI tests on Catalyst, TEST SUCCEEDED), release artifacts uploaded, `publish-release`
  correctly skipped under dry-run semantics. Green on the first attempt.

## Summary of changes

- Add `docs/releasing.md` covering:
  - Versioning scheme: semver `MARKETING_VERSION` + integer `CURRENT_PROJECT_VERSION`,
    `project.yml` as the single source of truth, manual edits discouraged; bump procedure via
    `just bump <major|minor|patch>`; tags-only model (annotated `v<semver>` on `main`).
  - Step-by-step release runbook: bump PR (version + CHANGELOG finalization) → merge via normal
    CI + SHA-bound `code-owner-review` gate → annotated tag → release workflow → verify GitHub
    Release + artifacts (checksums included).
  - Each release quality gate and what it protects, plus local equivalents
    (`just release-check`, `just archive`), including the recorded story 003 outcome (unsigned
    device archive vs. Catalyst fallback and the `.ipa` feasibility result) and the `test-mac`
    deviation note.
  - A clearly-marked **"When the Apple Developer account exists"** section: exact
    `DEVELOPMENT_TEAM`/`CODE_SIGN_STYLE` settings for `project.yml`, exact secret names
    (App Store Connect API key id, issuer id, `.p8` key content), the `APPSTORE_UPLOAD_ENABLED`
    repo variable to flip, the ExportOptions plist to add, and which `release.yml` placeholder
    steps become live — with the note that upload tooling must be re-verified at switch-on time
    and that creating secrets is a human action.
- Add a `docs/releasing.md` link to the README docs index.

Docs-only change: `ci.yml`, `lint.yml`, and `secret-scan.yml` are untouched.

## Test plan

- [x] `release.yml` dry-run completed green with no Apple credentials:
      https://github.com/beyerja/ProjectHana/actions/runs/29126126066 (conclusion: success)
- [x] `just lint` green (yamllint/shellcheck/ruff lint gate passes on new Markdown)
- [x] No changes to per-PR blocking checks (`ci.yml`, `lint.yml`, `secret-scan.yml`)
- [ ] PR CI checks green
- [ ] `code-owner-review` gate posted on the head SHA
