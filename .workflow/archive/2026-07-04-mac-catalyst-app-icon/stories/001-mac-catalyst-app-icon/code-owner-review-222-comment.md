<!-- code-owner-review -->
## Code-owner review: APPROVED

**Verdict:** APPROVED — merge gate (`code-owner-review`) set to `success`.

**Diff reviewed directly** (not via `/code-review` skill):

- Archives completed `mac-catalyst-app-icon` workflow to `.workflow/archive/2026-07-04-mac-catalyst-app-icon/` — purely organizational, no production code touched.
- Adds "Autonomous execution — do NOT stop between steps" directive to `.claude/agents/feature_orchestrator.md` and `.claude/agents/story-workflow.md` — process improvement directives, user-approved.
- Also adds pre-spawn idempotency check reminder in feature-orchestrator story loop.
- All CI checks pass: Build & Test, gitleaks, Lint (all languages), Detect build-relevant changes — all `pass`.
- No blockers. No correctness issues. No regressions possible from archiving workflow files or adding instructional text to agent markdown.

**Gate check:** `code-owner-review` posted as `success` on SHA `deda4a073f10f5d1efe79a6a50167350386b7f5b` by App id `4144849` (`hanahuac-review-bot`).
