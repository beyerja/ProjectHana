# Story 003: evaluate-workflow analysis & gated remediation

## Title
Analyze the permission capture in evaluate-workflow and apply or propose remedies under a security bar

## Goal
Have `evaluate-workflow` consume the permission-capture sink from Story 001, surface the
prompted-command distribution, and for each frequently-prompted signature emit a remedy that is
either auto-applied (when uncritical) or proposed-and-held (when it touches security) — so future
runs prompt the user less.

(The permission-capture sink is produced by the permission-capture hook story.)

## Scope
- Edit `.claude/agents/evaluate-workflow.md` only (instructions for the agent). No new app code.
- Reads `.workflow/telemetry/permissions-<date>.jsonl` produced by the permission-capture hook
  story. If the file is absent or empty, the phase is a graceful no-op (this story must not assume
  captures exist, so the build/run is never red between stories).

## Behavior (added to evaluate-workflow's telemetry phase)
- Read the current run's permission-capture file(s); group records by `signature`; count frequency.
- Emit a distribution table (signature → count) in the evaluation report so the user can see what
  drove each recommendation.
- For each frequent signature, decide a remedy and classify it against the security bar:
  - **Auto-apply** (uncritical): the command is deterministic and side-effect-bounded. Remedy =
    add a named `just` recipe wrapping it plus a single `Bash(just <recipe> *)` allow entry, OR add
    an agent instruction to prefer an existing safe recipe. Apply it within the same run.
  - **Propose-and-wait** (security-sensitive): the command or its allow pattern is destructive
    (rm/mv/overwrite outside scratch), network-fetching, privilege-changing, or wildcard-injectable
    (a `*` could match arbitrary shell). Output the proposal and make NO edit until the user confirms
    — mirroring the existing Phase 2a bloat-audit propose-and-wait behavior.
- Never auto-add a broad or injectable allow pattern; when in doubt, propose.
- Only the current run's capture is analyzed (no retroactive allowlisting of past runs).

## Acceptance Criteria
- [ ] `evaluate-workflow.md` instructs the agent to read the permission capture, group by
      `signature` with counts, and include the signature→count distribution in its report.
- [ ] Each frequent signature is classified as auto-apply or propose-and-wait per the stated
      security bar (deterministic + side-effect-bounded ⇒ auto-apply; destructive / network /
      privilege / wildcard-injectable ⇒ propose-and-wait).
- [ ] For an auto-apply remedy, the agent actually applies it within the same run: adds the `just`
      recipe and/or the single `Bash(just <recipe> *)` allow entry, or adds the agent instruction.
- [ ] For a propose-and-wait remedy, the agent outputs the proposal and makes NO edit until the
      user confirms.
- [ ] The instructions explicitly forbid auto-adding broad/injectable allow patterns and direct the
      agent to propose when uncertain.
- [ ] An absent or empty capture file is handled as a graceful no-op (no error, no spurious edits).

## Dependencies
- Builds on the permission-capture hook story's sink format (`ts`, `tool`, `command`, `signature`).
  Tolerates an empty/missing sink so it can ship independently.

## Conventions
- `just`-based recipes; Nix/direnv PATH (no hardcoded `/nix`). Do not weaken security.
