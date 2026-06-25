<!-- code-owner-review -->
## Code-owner review — round 1: APPROVED

Independent second-pass review of PR #169 (`just ui-walkthrough` recipe + helper + docs) against the story 003 acceptance criteria. Reviewed the diff directly (not via /code-review); distinct cold-context agent from both the implementer and the first reviewer, with my own verdict. Formal `Hanahuac-Bot` APPROVE submitted and confirmed via read-back.

### Runtime reachability (traced, not assumed)
The env seam is wired end-to-end: helper exports `TEST_RUNNER_HANA_UI_SCRIPT_PATH` / `TEST_RUNNER_HANA_REPO_ROOT` / `TEST_RUNNER_HANA_UI_RUN`; xcodebuild strips the `TEST_RUNNER_` prefix and the driver reads the bare keys — `HANA_UI_SCRIPT_PATH` (`UIActionScript.swift`), `HANA_REPO_ROOT` + `HANA_UI_RUN` (`UIWalkthroughRecorder.swift`). The recipe targets the real test `HanahuacUITests/UIDriverTests/testRunUIScript`. Names match exactly, so the artifact-collection AC is reachable in a real run.

### Acceptance criteria
- **Recipe** — builds + runs only `testRunUIScript` against booted `{{sim}}` with per-worktree `{{sim_dd}}`, prints artifact dir, glue in `scripts/ui-walkthrough.sh`. Allowlistable (no `cd &&`, no heredoc, no committed `$(…)`, no poll loop). ✓
- **Helper** — shebang + `set -euo pipefail` + quoted vars; resolves run dir + plumbs the env contract; no driver source touched. ✓
- **Canonical locations + example** — `smoke.json` matches the documented schema. ✓
- **README** — JSON schema, supported actions, env-var contract, artifact locations, write→run→read loop, and the "~tens of seconds, not live frame-by-frame" reality all documented. ✓
- **Tree hygiene** — `.gitignore` ignores run-output dirs while keeping `scripts/` + `README.md` tracked; no run-output committed. ✓

### Non-blocking (concur with first reviewer)
`xcodebuild test … | grep … || true` swallows the test exit status, but the `000-step.png` / `000-step.json` existence checks are the real failure gate. Acceptable as-is.

### CI head
Commit `7ff7717`: **Build & Test = success**, **Detect build-relevant changes = success**. Both required contexts present and green; no self-heal needed.

**Verdict: APPROVED.**
