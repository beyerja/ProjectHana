<!-- independent-review -->
## Independent review — APPROVED (round 1)

Cold-context 4-eye review of this doc-only change (`.claude/agents/verify-story.md`, `.claude/agents/verify-feature.md`) against the story spec. **No blocking findings.**

### Acceptance criteria
- **AC1 (verify-story.md)** ✅ `just ui-walkthrough` is now the **default** verification triggered by changed files under `Hanahuac/Views/**`, explicitly not gated on the opt-in `## Visual Verification` section ("its absence does not skip the walkthrough"). Per-step screenshots **and** accessibility dumps are inspected; sim-unavailable fallback retained.
- **AC2 (verify-feature.md)** ✅ The single static end-to-end screenshot is replaced by a broad **multi-screen** walkthrough that navigates across every affected flow and inspects per-step dumps.
- **AC3 (both)** ✅ Both agents enumerate the three concrete bug classes (empty a11y tree = crash/app-gone; untranslated text; duplicated/missing/obscured/overlapping controls) and instruct **FAIL + loop back**, not merely "matches the spec."
- **Doc-only scope** ✅ Only the two `.md` files change. Edits integrate into existing structure; `## Outcomes`/telemetry blocks intact. All driver references verified accurate (`scripts/ui-walkthrough.sh`, `just ui-walkthrough`, `.workflow/ui-walkthrough/README.md` incl. the story-001 `pinch` action, `HanahuacUITests/UIActionScript.swift` + `UIDriverTests.swift`; `NNN-step.png`/`.json` + step `000` naming confirmed against the driver). New Bash shapes are allowlistable and the old `$(…)` launch fallback was removed.

### Non-blocking nit (1, posted inline)
The sim-unavailable **fallback** in both files calls `just screenshot-sim .workflow/screenshots/...` but drops the `mkdir -p` the replaced steps had. `screenshot-sim` does not create its parent dir and `.workflow/screenshots/` is gitignored, so on a fresh checkout the fallback screenshot write fails — loud (non-zero, clear error), degraded-path only, no AC impact. Optional to address.

Note: this verdict does not set the formal `code-owner-review` merge-gate check — that is posted by the separate code-owner-review agent.
