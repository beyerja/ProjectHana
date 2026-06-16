# Story 002: Permission-capture PreToolUse hook

## Title
Capture every would-prompt Bash command into a gitignored telemetry sink

## Goal
Automatically record every `Bash` command that would trigger a permission prompt (i.e. is
NOT matched by the effective allowlist) so a later phase can analyze the distribution. This
story ships the capture mechanism end-to-end and is independently testable: run the hook with
a sample payload and confirm the right lines land in the sink.

## Scope
- New script `scripts/permission-capture-hook.sh` (dependency-light, fast, fails open).
- Register it as a `PreToolUse` hook in `.claude/settings.json` (matcher targets Bash; existing
  PostToolUse telemetry hook untouched).
- Add the single `Bash(bash scripts/permission-capture-hook.sh*)` allow entry so the hook
  invocation itself never prompts.

## Behavior
- On each `PreToolUse` event for tool `Bash`, read the command from the hook payload.
- Compute the effective allowlist by merging `permissions.allow` from BOTH
  `.claude/settings.json` and `.claude/settings.local.json` (local file optional).
- If the command IS matched by an allow pattern, do nothing (no record, no false positive).
- If the command is NOT matched, append one JSON line to
  `.workflow/telemetry/permissions-<date>.jsonl` with at minimum:
  - `ts` (ISO-8601 UTC),
  - `tool` (e.g. `Bash`, included for future-proofing),
  - `command` (raw command string),
  - `signature` (normalized: leading executable + first subcommand, so repeats group).
- Non-Bash tools: record only the tool name field (do not attempt command matching); MCP/other
  prompt capture beyond the tool-name field is out of scope.
- The hook MUST fail open: any error (missing file, malformed payload, parse failure) exits 0
  without blocking or erroring the tool call.

## Acceptance Criteria
- [ ] `scripts/permission-capture-hook.sh` exists, is invoked via a `PreToolUse` hook registered
      in `.claude/settings.json`, and the PostToolUse telemetry hook is unchanged.
- [ ] A Bash command not matched by the effective allowlist produces exactly one appended line in
      `.workflow/telemetry/permissions-<date>.jsonl` with `ts`, `tool`, `command`, `signature`.
- [ ] A Bash command already covered by an allow pattern produces NO line (no false positives) —
      verified against at least one existing entry from each of `.claude/settings.json` and
      `.claude/settings.local.json`.
- [ ] Allowlist matching reads BOTH `.claude/settings.json` and `.claude/settings.local.json`
      `permissions.allow`; absence of the `.local` file is handled gracefully.
- [ ] The hook fails open: a malformed/empty payload or missing settings file exits 0 and writes
      nothing fatal, never blocking the tool call.
- [ ] The capture file path is covered by the existing `.workflow/telemetry/*.jsonl` gitignore
      rule and is never committed (verified against `.gitignore`).
- [ ] A single `Bash(bash scripts/permission-capture-hook.sh*)` allow entry is added so the hook
      itself does not prompt; no broad/injectable pattern is introduced.

## Conventions
- Reuse the existing `scripts/telemetry-hook.sh` pattern; Nix/direnv PATH (no hardcoded `/nix`).
- Keep the hook fast and dependency-light (runs on every tool call).
