# Tasks — 004 Release CI workflow

Grounding (verified against the worktree at breakdown time):

- Reuse, don't duplicate: `just archive` (proven unsigned device Release archive +
  `scripts/package-ipa.sh` ipa), `just release-check` components (`lint`, `geo-packs-check`,
  `verify-odr-packs`, `verify-base-only-release`), `scripts/check-tag-version.sh`,
  `scripts/check-changelog.sh`. Story 003 log is binding: `generic/platform=iOS`,
  `CODE_SIGNING_ALLOWED=NO`, no Catalyst fallback needed; ipa = plain `ditto --norsrc` zip.
- The flake's DEFAULT dev shell (macOS-capable, `mkShellNoCC`) already contains `just`,
  `direnv`, `xcodegen`, `gh` + all linters — so on the macos-15 runner the pattern is
  install Nix (as lint.yml does) → `direnv allow` inside `nix develop` → run `nix develop
  --command just <recipe>` for exact local parity (the just recipes call `direnv exec .`).
- Full-test caveat: `just test-mac` bakes in `-skip-testing:HanahuacUITests` (local-only
  limitation). CI executes UITests on Catalyst (established convention, ci.yml does), so the
  release workflow's test gate must mirror ci.yml's `xcodebuild test` step, NOT `test-mac`.
- In-repo action pins at breakdown time: `actions/checkout@v7` (ci/lint/odr/codeql/secret-scan/
  update-flake-lock), `cachix/install-nix-action@v31` (lint.yml), `dorny/paths-filter@v4`,
  `DeterminateSystems/nix-installer-action@v22`, `github/codeql-action@v4`. upload/download-
  artifact are NOT yet used anywhere — their majors must be verified (task 001).
- yamllint: line-length max 200 is a warning (non-blocking); actionlint runs in `just lint`.
- MARKETING_VERSION is currently "1.0.0" and CHANGELOG.md has a `## [1.0.0]` section — usable
  as local fixtures for end-to-end command rehearsal.

## Tasks

- [x] 001: Verify GitHub Action versions empirically and record the evidence. Grep the
      in-repo pins (`actions/checkout@v7`, `cachix/install-nix-action@v31`) and query the
      marketplace/API (`gh api repos/actions/upload-artifact/releases/latest`, same for
      `download-artifact`) for the current majors of every action release.yml will use.
      Do NOT assume versions from training data. Append the verified list + evidence source
      to `<story-dir>/log.md` so create-pr can copy it into the PR description (spec AC).

- [x] 002: Add `scripts/extract-changelog-section.sh` — prints the BODY of the
      `## [X.Y.Z]` Keep-a-Changelog section (heading line excluded, content up to the next
      `## [` heading or EOF) to stdout. CLI mirrors `check-changelog.sh` exactly:
      optional `X.Y.Z` positional (else derived from the single `MARKETING_VERSION: "…"`
      line in project.yml), `--changelog <path>`, `--project-yml <path>`; strict-semver
      validation; one-line stderr + non-zero exit when the section is missing or its body is
      empty/whitespace-only. `set -euo pipefail`, shellcheck-clean. Used by the publish job
      to build the GitHub Release body.

- [x] 003: Add `scripts/test-extract-changelog-section.sh` (temp-fixture tests via
      `--changelog`/`--project-yml`, mirroring `test-check-changelog.sh` + `test-lib.sh`
      conventions: section found mid-file, section-at-EOF, missing section fails,
      empty body fails, version derived from project.yml). Wire it into the
      `test-release-scripts` just recipe and run `just test-release-scripts` green.

- [x] 004: Create `.github/workflows/release.yml` skeleton: explanatory header comment in
      repo style (why there is NO `pull_request` trigger, why the per-PR blocking set —
      ci.yml/lint.yml/secret-scan.yml — is untouched, dry-run semantics); triggers:
      `push: tags: ['v*']` AND `workflow_dispatch` with a boolean `dry_run` input
      (default true, described); top-level `permissions: contents: read`; concurrency
      group `release-${{ github.ref }}` with `cancel-in-progress: false` (never cancel an
      in-flight publish — deliberate deviation from lint.yml's cancel-true, comment why).
      Dry-run expression used throughout:
      `github.event_name == 'workflow_dispatch' && inputs.dry_run` (on tag-push events
      `inputs` is empty so this evaluates false).

- [x] 005: Gates job `gates-and-artifacts` (runs-on macos-15, `timeout-minutes: 90`,
      job `permissions: contents: read`) — bootstrap + ordered fast gates (a)/(b):
      checkout@<verified>; Install Nix via `cachix/install-nix-action@v31` with the exact
      lint.yml `extra_nix_config`; `nix develop --command direnv allow .` (makes the just
      recipes' `direnv exec .` calls work on the runner);
      gate (a) tag↔version: step `if: github.ref_type == 'tag' && !<dry-run expr>` running
      `bash scripts/check-tag-version.sh "${{ github.ref_name }}"`, plus a companion
      inverse-condition step echoing WHY it was skipped (dry-run or no tag ref);
      gate (b) changelog: `bash scripts/check-changelog.sh` — pass the tag's X.Y.Z base when
      `github.ref_type == 'tag'`, otherwise no arg (derives from project.yml).

- [x] 006: Gates (c)–(g) as ordered steps in the same job, each failing the run on
      violation: (c) `nix develop --command just lint` (full lint suite, local parity);
      (d) `nix develop --command just generate` (xcodegen) then FULL Catalyst test —
      copy ci.yml's `xcodebuild test` step verbatim (Debug config, unsigned flags,
      `set -o pipefail`, NO `-skip-testing`: CI executes HanahuacUITests on Catalyst);
      (e) `nix develop --command just geo-packs-check`;
      (f) `nix develop --command just verify-odr-packs`;
      (g) `nix develop --command just verify-base-only-release` (Release Catalyst build +
      `verify-base-only-bundle.sh`, reusing the story-003 recipe).

- [x] 007: Artifact steps (same job, after all gates): `nix develop --command just archive`
      (produces `/tmp/Hanahuac-archive/Hanahuac.xcarchive` + `Hanahuac.ipa` — HANA_FEATURE_SLUG
      is unset on the runner so `_sfx` is empty; do NOT re-implement archive/ipa logic in
      YAML); zip the archive with `ditto -c -k --norsrc --keepParent <…>/Hanahuac.xcarchive
      Hanahuac.xcarchive.zip` (--norsrc per story-003 finding: avoids AppleDouble/`__MACOSX`
      pollution); generate `SHA256SUMS.txt` with `shasum -a 256` over the zip + ipa (run in
      the staging dir so the checksum file contains bare filenames); upload all three files
      as one artifact via `actions/upload-artifact@<verified-major from task 001>`.

- [x] 008: Publish job `publish-release` (runs-on ubuntu-latest, `needs:` the gates job,
      `if: github.ref_type == 'tag' && !<dry-run expr>`, job-level
      `permissions: contents: write` — the ONLY write grant in the workflow):
      checkout (for CHANGELOG.md + scripts); `actions/download-artifact@<verified>`;
      build the release body file with `bash scripts/extract-changelog-section.sh <tag base>`
      redirected to a file; create the release with
      `gh release create "$TAG" <zip> <ipa> <SHA256SUMS.txt> --title "$TAG" --notes-file
      <body-file> --generate-notes` (`GH_TOKEN: ${{ github.token }}`), adding `--prerelease`
      when the tag has a semver suffix (`contains(github.ref_name, '-')`).
      VERIFY EMPIRICALLY first (throwaway repo or `gh api repos/{owner}/{repo}/releases
      --method POST` docs check) that gh combines `--generate-notes` with `--notes-file`
      (the REST API prepends the body to generated notes); if the CLI rejects the combo,
      fall back to `gh api .../releases/generate-notes` + concatenation. Record the
      verification outcome in the story log.

- [x] 009: App Store Connect / TestFlight placeholder steps (publish job, after release
      creation): a clearly-labeled "Upload to App Store Connect / TestFlight (placeholder)"
      step gated on `vars.APPSTORE_UPLOAD_ENABLED == 'true'` AND non-empty
      `secrets.APP_STORE_CONNECT_KEY_ID` / `APP_STORE_CONNECT_ISSUER_ID` /
      `APP_STORE_CONNECT_PRIVATE_KEY` that only echoes what a real upload would do (no
      Apple account exists — nothing may require signing or credentials); plus a companion
      inverse-condition step that logs an explanatory line (upload disabled: variable unset
      and/or API-key secrets absent) so the workflow succeeds end-to-end with a clear skip
      message. Comment both steps as the activation point for the future Developer account.

- [x] 010: Validation pass, all local: `just lint` green (yamllint + actionlint over
      release.yml, shellcheck over the two new scripts); `just test-release-scripts` green;
      rehearse the workflow's script invocations against the real repo state
      (`bash scripts/check-tag-version.sh v1.0.0`, `bash scripts/check-changelog.sh`,
      `bash scripts/extract-changelog-section.sh 1.0.0` — MARKETING_VERSION is 1.0.0 with a
      matching CHANGELOG section); confirm `git status`/diff shows ci.yml, lint.yml and
      secret-scan.yml byte-for-byte untouched (spec constraint: per-PR blocking set
      unchanged).
