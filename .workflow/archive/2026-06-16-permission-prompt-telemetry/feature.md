# Feature: Permission-prompt telemetry → evaluate-driven allowlisting

## Goal
Reduce the number of permission prompts the user has to approve during a workflow run.
Automatically capture every Bash command that *would* trigger a permission prompt (i.e. is
not matched by the existing allowlist), then have `evaluate-workflow` analyze that capture and
either (a) collapse a safe, repeated command into a named `just` recipe + a single pre-approved
allow entry, or (b) instruct the responsible agent to avoid the call — with the choice gated by a
security judgment.

## Goal detail / design decisions (from clarification)
- **Capture is automatic and hook-based**, not agent self-report. Agents cannot observe their own
  permission prompts; a `PreToolUse` hook is the reliable signal. The hook matches each `Bash`
  command against the effective allowlist (`.claude/settings.json` + `.claude/settings.local.json`
  `permissions.allow`) and records the ones that would NOT auto-approve.
- **Storage:** append records to `.workflow/telemetry/permissions-<date>.jsonl`. Already covered by
  the existing `.workflow/telemetry/*.jsonl` gitignore rule — never committed.
- **Record shape (per line):** at minimum `ts`, the raw command, and a normalized command "signature"
  (e.g. the leading executable + first subcommand, so repeats group together). Tool name included for
  future-proofing even though the matcher targets Bash.
- **`evaluate-workflow` consumes the capture** in its telemetry phase: group by signature, count
  frequency, and for each frequently-prompted signature decide a remedy.
- **Auto-apply vs. propose-and-wait:**
  - *Auto-apply* when the remedy is uncritical — e.g. add a `just` recipe wrapping a deterministic,
    side-effect-bounded, read-only-ish command and a single `Bash(just <recipe> *)` allow entry; or
    add an agent instruction to prefer an existing safe recipe.
  - *Propose-and-wait* (no edit without explicit user approval, like the existing Phase 2a bloat audit)
    when the command — or allowlisting it — could be a security concern.
- **Security bar for allowlisting:** only auto-allow commands that are deterministic and
  side-effect-bounded. Anything destructive (rm/mv/overwrite outside scratch), network-fetching,
  privilege-changing, or wildcard-injectable (where a `*` in the allow pattern could match arbitrary
  shell) must NOT be auto-allowed — for those, recommend instructing the agent to avoid the call, or
  propose the change and wait.

## Acceptance Criteria
- [ ] A `PreToolUse` hook (registered in `.claude/settings.json`) records every Bash command that is
      not matched by the effective allowlist into `.workflow/telemetry/permissions-<date>.jsonl`.
- [ ] The capture file is gitignored and never committed (verified against `.gitignore`).
- [ ] Allowlist matching in the hook reads BOTH `.claude/settings.json` and
      `.claude/settings.local.json` `permissions.allow`, and a command already covered by an allow
      pattern is NOT recorded (no false positives for pre-approved commands).
- [ ] The hook never blocks or errors a tool call — it is best-effort and fails open (a broken hook
      must not break the workflow).
- [ ] `evaluate-workflow.md` is updated to: read the permissions capture, group by command signature
      with counts, and for each frequent signature emit a remedy classified as auto-apply or
      propose-and-wait per the security bar above.
- [ ] For an auto-apply remedy, `evaluate-workflow` actually applies it (adds the `just` recipe and/or
      the single allow entry, or adds the agent instruction) within the same run.
- [ ] For a propose-and-wait remedy, `evaluate-workflow` outputs the proposal and makes NO edit until
      the user confirms.
- [ ] The evaluation report shows the prompted-command distribution (signature → count) so the user
      can see what drove each recommendation.

## Constraints
- Follow project conventions: `just`-based recipes, Nix/direnv PATH (no hardcoded `/nix` paths),
  shell scripts under `scripts/`.
- The hook must be fast and dependency-light (it runs on every tool call). Reuse the existing
  telemetry-hook pattern (`scripts/telemetry-hook.sh`, registered under `hooks` in settings.json).
- Do not weaken security: never auto-add a broad/injectable allow pattern. When in doubt, propose.
- Permission capture is local-only telemetry; treat it like the existing telemetry sink.

## Out of Scope
- Capturing non-Bash tool permission prompts (MCP, etc.) beyond recording the tool name field.
- Building a UI/dashboard for the capture.
- Retroactively allowlisting commands from past runs (only the current run's capture is analyzed).
- Changing the existing PostToolUse telemetry hook behavior.
