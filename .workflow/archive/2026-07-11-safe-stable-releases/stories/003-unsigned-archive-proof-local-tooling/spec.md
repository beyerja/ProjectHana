# 003 — Empirical unsigned-archive proof + local release tooling

## Title
Prove the unsigned Release archive path empirically; deliver `just archive` and `just release-check`

## Goal
Per the feature's Constraints section and the project's "verify external assumptions empirically"
rule, this story MUST prove with a throwaway run — BEFORE the release workflow (story 004) is built
on it — that an unsigned Release-configuration `xcodebuild archive` (`generic/platform=iOS`,
`CODE_SIGNING_ALLOWED=NO`) works, and whether an unsigned `.ipa` (zip of `Payload/Hanahuac.app`)
is feasible. It then encodes the proven commands as `just archive` and delivers `just release-check`
(the full local release quality bar). The recorded outcome (device archive OK vs. documented
Catalyst fallback) is a binding input to stories 004 and 005.

## Acceptance Criteria
- [ ] An empirical throwaway run of `xcodebuild archive` with Release configuration and
      `CODE_SIGNING_ALLOWED=NO` (unsigned, `generic/platform=iOS`) is performed FIRST and its
      outcome (success, or failure + chosen fallback) is recorded in the story log before any
      workflow-facing tooling is finalized.
- [ ] If the unsigned device archive is infeasible, the documented fallback is adopted and recorded:
      unsigned Mac Catalyst Release archive + an unsigned device *build* artifact, with a note that
      the signed device archive activates with the Apple Developer account (to be reflected in
      `docs/releasing.md` by story 005).
- [ ] `just archive` exists, produces the unsigned Release `.xcarchive` locally using the proven
      command, preserves the repo's per-worktree DerivedData conventions, and emits the resulting
      `.xcarchive` path.
- [ ] The `.ipa` feasibility question is answered empirically: either `just archive` (or a
      companion recipe/script step) also packages an unsigned `.ipa`, or infeasibility is recorded
      with the reason for stories 004/005 to consume.
- [ ] `just release-check` exists and passes locally, running the full release quality bar: lint
      suite, full test suite (Mac Catalyst destination, as ci.yml does), `generate-geo-packs.py
      --check`, `verify-odr-packs.sh`, Release-config build + `verify-base-only-bundle.sh`, plus the
      changelog and version consistency checks from story 002.
- [ ] Nothing in the delivered tooling requires signing or Apple credentials to succeed.
- [ ] New shell passes shellcheck / new Python passes ruff; the existing lint gate stays green.

## Constraints (repo-wide, apply to this story)
- Zero changes to per-PR blocking checks (`ci.yml`, `lint.yml`, `secret-scan.yml` untouched).
- Allowlistable command shapes only (no `cd &&`, no heredocs, no `$(…)` payloads, no poll loops).
- Nix flake/direnv for tooling; no hardcoded /nix paths.
- Merge gate: normal CI + SHA-bound `code-owner-review` status check; nothing may bypass or weaken it.

## Dependencies
- 002 (consistency-check scripts consumed by `just release-check`).
