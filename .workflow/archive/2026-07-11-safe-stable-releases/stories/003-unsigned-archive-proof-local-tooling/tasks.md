# Tasks — 003 unsigned-archive-proof-local-tooling

## Tasks
- [x] 001: Empirical throwaway proof of the unsigned device archive. Run
      `xcodebuild archive -project Hanahuac.xcodeproj -scheme Hanahuac -configuration Release
      -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
      CODE_SIGNING_ALLOWED=NO` with a throwaway `-archivePath` and `-derivedDataPath` under
      `/tmp/Hanahuac-archive-proof-$HANA_FEATURE_SLUG` (per-worktree isolation, do NOT reuse
      `mac_dd`/`sim_dd`). Run in FOREGROUND with a generous Bash timeout (600000 ms — archive
      builds are slow). Capture the tail of the output; on failure capture the exact error.
      This is a throwaway run — commit nothing from it; it only produces evidence.
- [x] 002: Empirical throwaway proof of unsigned `.ipa` packaging. If 001 succeeded, take the
      throwaway `.xcarchive`, copy `Products/Applications/Hanahuac.app` into a `Payload/` dir and
      zip it to `Hanahuac.ipa` (plain `zip`/`ditto`, no signing); confirm the zip is produced and
      structurally sane (`unzip -l` shows `Payload/Hanahuac.app/...`). If 001 failed, instead run
      the spec's documented fallback proof: unsigned Mac Catalyst Release
      `xcodebuild archive` (destination `platform=macOS,variant=Mac Catalyst`, same unsigned
      flags) plus an unsigned device *build* (`xcodebuild build -destination
      'generic/platform=iOS' …`), each foreground with timeout up to 600000 ms.
- [x] 003: Record the binding proof outcome in the story log
      `<story-dir>/log.md` (append with the Edit tool, never heredoc): which path was proven
      (unsigned device archive OK, or Catalyst-archive fallback adopted + why), the exact proven
      command lines, whether unsigned `.ipa` packaging is feasible (and if not, the concrete
      reason), and a note that stories 004/005 must consume this outcome (005 reflects any
      fallback in `docs/releasing.md`). This MUST land before the recipes below are finalized.
- [x] 004: Add `just archive` to the justfile encoding the PROVEN command from 001/002 (or the
      fallback from 002). Requirements: Release configuration, fully unsigned
      (`CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`, no credentials
      needed), per-worktree isolation via a new suffixed variable following the existing pattern
      (e.g. `archive_dd := "/tmp/Hanahuac-archive-build" + _sfx` and an archive output path with
      `_sfx`), and it must echo the resulting `.xcarchive` path as its final output. If `.ipa`
      packaging was proven feasible, include the `Payload/` zip step (in the recipe or a small
      `scripts/*.sh` helper) and echo the `.ipa` path too; if infeasible, omit it (003's log entry
      is the record). Recipe body must be allowlist-friendly for callers (`just -f <dir>/justfile
      archive` works from anywhere) and any new shell must be shellcheck-clean.
- [x] 005: Add `just release-check` to the justfile: the full local release quality bar, failing
      on the first broken step and printing a clear per-step banner. Steps, reusing existing
      recipes/scripts rather than duplicating commands: (1) `lint` (full suite incl. l10n-check),
      (2) full test suite on the Mac Catalyst destination exactly as ci.yml runs it
      (`xcodebuild test … 'platform=macOS,variant=Mac Catalyst' -configuration Debug` with the
      unsigned flags and per-worktree DerivedData — note the existing `test` recipe uses the
      simulator, so this needs the Catalyst invocation), (3) `generate-geo-packs.py --check`
      (via `geo-packs-check`), (4) `verify-odr-packs`, (5) a Release-configuration Mac Catalyst
      build followed by `verify-base-only-bundle.sh` against that build's DerivedData (the
      existing `verify-base-only` depends on the Debug `build-mac`, so wire a Release-config
      variant), (6) story 002's consistency checks: `check-changelog` (version derived from
      project.yml when no arg) and the tag/version check — accept an optional `tag` argument so
      `just release-check v1.2.3` also runs `check-tag-version`, and skip that step with an
      explicit "no tag given" note when omitted. Nothing may require signing or Apple
      credentials; zero changes to ci.yml / lint.yml / secret-scan.yml.
- [x] 006: Run `just archive` end-to-end in the worktree (foreground, timeout up to 600000 ms)
      and confirm it emits an existing `.xcarchive` path (and `.ipa` if applicable); then run
      `just release-check` end-to-end and confirm it passes locally. Fix anything it surfaces.
      Expect long runtimes; keep each xcodebuild step a single foreground Bash call.
- [x] 007: Run `just lint` and confirm the whole gate stays green (shellcheck for any new/edited
      shell, yamllint untouched-workflow check, ruff if any Python was touched). Fix violations.
      Commit via Write-tool message file + `git -C <worktree> commit -F <file>` per repo
      conventions.
