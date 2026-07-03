<!-- code-owner-review -->
## Code owner review — APPROVED

Independent second-eye re-verification of this doc-only change
(`.claude/agents/verify-story.md`, `.claude/agents/verify-feature.md`) against the story spec,
reviewed directly (not via `/code-review`). **No blocking findings.** I reached this verdict
independently, with the `independent-review` round-1 findings as input.

### Acceptance criteria
- **AC1 (verify-story.md)** ✅ `just ui-walkthrough` is the **default** verification, triggered by
  changed files under `Hanahuac/Views/**` and explicitly not gated on the opt-in
  `## Visual Verification` section ("its absence does not skip the walkthrough"). Per-step screenshots
  **and** accessibility dumps inspected. Sim-unavailable fallback present, and it now restores
  `mkdir -p .workflow/screenshots/<story-id>` before `screenshot-sim` — the prior round's nit is fixed.
- **AC2 (verify-feature.md)** ✅ The single static end-to-end screenshot is replaced by a broad
  **multi-screen** walkthrough navigating across every affected flow, inspecting per-step dumps. The
  fallback likewise restores `mkdir -p .workflow/screenshots`.
- **AC3 (both)** ✅ Both agents enumerate the three concrete bug classes (empty a11y tree =
  crash/app-gone; untranslated text; duplicated/missing/obscured/overlapping controls) and instruct
  **FAIL + loop back**, not merely "matches the spec."
- **Doc-only scope** ✅ Only the two `.md` files change; edits integrate into existing structure;
  `## Outcomes`/telemetry blocks intact; driver references accurate (`just ui-walkthrough`,
  `.workflow/ui-walkthrough/README.md` incl. the story-001 `pinch` action, `scripts/ui-walkthrough.sh`,
  `NNN-step.png`/`.json` + step `000` naming). New Bash shapes are allowlistable.

### Merge gate
Required `code-owner-review` status check posted on head `b1bcf57ec264663cc136d6dc00321a6aefe40995`
→ conclusion **success**, app id **4144849** (read-back confirmed). CI required contexts
(`Build & Test`, `gitleaks`) already present and green on the head.
