# Story 003 — Apply the conventions to the concrete agent offenders

## Goal
Remove the specific instructions/examples in agent files that tell sub-agents to use
un-allowlistable shapes, replacing them with the CLAUDE.md-aligned forms.

## Changes
- `create-pr.md`: replace "Always pass body via HEREDOC to preserve formatting" with
  "write the body to a file and `gh pr create --body-file <file>`"; use `git push -u origin <branch>`
  at-path form.
- `merge-pr.md`: the post-merge chore commit uses `git commit -F <file>` (message written with the
  Write tool); avoid `if …; then …; fi` inline where a path-flag form works.
- `implement-story.md`: add a one-line pointer to the commit-via-`-F` convention; keep schema/lint
  guidance intact.
- `wait-for-ci.md`: add an explicit "do not hand-roll registration poll loops — a single
  `--watch` (optionally one `sleep` first) is enough" note.
- `feature_orchestrator.md` & `evaluate-workflow.md`: align the existing `cd`-avoidance prose to
  reference the shared CLAUDE.md convention (no behavior change, just consistency).

## Acceptance Criteria
- [ ] `create-pr.md` no longer instructs HEREDOC PR bodies.
- [ ] No agent file instructs a `cd <path> && …` compound, a `$(cat <<EOF)` commit, or a CI poll loop.
- [ ] Telemetry `just log …` lines and other intentionally-simple calls are unchanged.
- [ ] `just lint` passes.
