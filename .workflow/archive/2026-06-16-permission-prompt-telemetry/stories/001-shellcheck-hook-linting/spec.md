# Story 001: ShellCheck linting for hook scripts

## Title
Add shellcheck to the dev shell and a `just lint-sh` recipe so the new PreToolUse hook (and the
other `scripts/*.sh` hooks) are statically linted

## Goal
This feature ships a new fail-open `PreToolUse` shell hook under `scripts/` that runs on every
tool call and parses untrusted JSON payloads. Its acceptance criteria demand it "fail open" and
handle malformed/missing input without ever blocking a tool call — exactly the quoting,
word-splitting, and portability classes of bug that `shellcheck` catches. Today the project has
NO shell-script static analysis: the flake dev shell installs `swiftformat` for Swift but no
`shellcheck`/`shfmt`, and CI lints only Swift. This story closes that gap so the new hook and the
existing hook scripts (`scripts/telemetry-hook.sh`, `scripts/agent-log.sh`, `scripts/install-mac.sh`)
are linted.

## Scope
- Add `shellcheck` to the flake dev shell `packages` in `flake.nix` (alongside the existing tools;
  no hardcoded `/nix` paths — it comes from the flake via direnv, per project convention).
- Add a `just lint-sh` recipe that runs `shellcheck` over the repo's shell scripts
  (`scripts/*.sh` and any other tracked `.sh` files).
- Keep it dependency-light and consistent with existing `just` recipes (PATH via the flake/direnv).

## Out of Scope
- `shfmt` auto-formatting (lint-only for now).
- A shell unit-test framework (`bats`/`shunit2`) — the hook is validated by its own story's
  payload-driven acceptance checks; full shell test harness is not warranted yet.
- Wiring shell linting into the GitHub Actions CI workflow. (CI integration can follow once the
  local recipe is proven; this story is the local-tooling gap only, and avoids restructuring the
  Swift-focused CI.)
- Any Swift/app-side tooling.

## Behavior
- After `direnv allow`, `shellcheck` is available on PATH in the dev shell.
- `just lint-sh` exits non-zero if any in-scope shell script has a shellcheck finding, zero otherwise.
- The new `PreToolUse` hook script and the existing `scripts/*.sh` scripts pass (or have findings
  triaged/annotated with `# shellcheck disable=...` where a finding is a deliberate, justified choice).

## Acceptance Criteria
- [ ] `shellcheck` is listed in the `flake.nix` dev shell `packages` and resolves on PATH inside the
      dev shell (no hardcoded `/nix` path; provided via flake + direnv).
- [ ] A `just lint-sh` recipe exists and runs `shellcheck` over the tracked shell scripts under
      `scripts/` (and any other tracked `.sh`).
- [ ] `just lint-sh` passes cleanly against the current `scripts/*.sh` scripts (existing findings are
      either fixed or annotated with a justified `# shellcheck disable` directive).
- [ ] The new PreToolUse hook from story 002 is covered by `just lint-sh` and passes it.
- [ ] No Swift/app tooling or CI workflow files are modified by this story.

## Conventions
- Follow project conventions: `just`-based recipes; Nix/direnv PATH (no hardcoded `/nix` paths);
  shell scripts live under `scripts/`.
- Match the style of existing `justfile` recipes (comment header + command body).
