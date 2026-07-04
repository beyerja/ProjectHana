<!-- independent-review -->
## Independent review — Round 1: APPROVED

Cold-context 4-eye review of the diff (engine: `/code-review --comment`, high effort). No blocking findings; nothing to address.

**What was verified**

- **Faithful restore.** `scripts/full-walkthrough.json`, `scripts/smoke.json`, and `demo/README.md` are byte-identical to the pre-#199 canonical state (`6879e21^`). The restored capability matches the intended permanent driver (README + recipe-default `smoke.json` + `full-walkthrough.json` + `demo/` evidence).
- **Demo PNGs are real.** All 17 `demo/NNN-step.png` are non-zero (137 KB–1.16 MB) with matching `NNN-step.json` dumps; `013` is byte-identical to `000` exactly as `demo/README.md` documents.
- **No reference to the removed "Salir" control in the script.** `full-walkthrough.json` step 12 is `tap` identifier `BackButton`, not `Salir`. The `Salir` strings appear only inside the restored historical demo evidence (Spanish-locale capture) and its README — intentional verbatim restore, not a live control reference.
- **Recurrence is prevented.** `archive-workflow.md` now states "Never move or delete `.workflow/ui-walkthrough/`", and the old contradictory "Leave `.workflow/` empty except for `README.md`" line was fully replaced with a carve-out for the permanent dir. Wording is consistent with the justfile recipe default `.workflow/ui-walkthrough/scripts/smoke.json` (justfile L251/L257). No other `.claude/agents/` file deletes/cleans `.workflow/` in a way that would re-trigger this.
- **No dangling references.** Every live reference to `.workflow/ui-walkthrough/` (justfile, `scripts/ui-walkthrough.sh`, `verify-story`, `verify-feature`, README) resolves to a restored or runtime-generated path. `.gitignore` correctly tracks `scripts/`, `README.md`, `demo/` while ignoring per-run output.
- **Scripts valid + no convention violations.** Both action scripts validate against the driver schema; the prose edit introduces no non-allowlistable command shapes and breaks no CLAUDE.md rule.

**Verdict:** APPROVED. The formal merge-gate `code-owner-review` check is set by the separate code-owner-review step, not here.
