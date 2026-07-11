<!-- code-owner-review -->
## Code-owner review — APPROVED (gate check posted)

Independent second-pass verification of PR #225 (direct diff review, no skill re-run), against spec `001-fix-current-failures`:

- `dependabot.yml`: `swift` ecosystem entry removed with re-add guidance comment; `github-actions` entry unchanged; schema/lint green.
- `update-flake-lock.yml`: `peter-evans/create-pull-request` fully removed; `permissions:` exactly `contents: write` + `issues: write`; change detection gates all side effects (no-change → green no-op); force-push to `automated/update-flake-lock`; single-open-issue dedup via `flake-lock-update` label; handoff design documented in comments.
- Live state: `flake-lock-update` label exists; `can_approve_pull_request_reviews` still `false` — no repo-settings mutation anywhere.
- CI on head `29d81a2`: Build & Test, Lint, gitleaks, detect-changes all green (no self-heal needed).
- First reviewer's two findings (missing concurrency group; dispatched-ref force-push) independently judged non-blocking: weekly cron + idempotent dedup make collisions harmless, and any off-main dispatch is self-corrected by the next scheduled force-push.

**Gate:** `code-owner-review` check posted with conclusion `success` on `29d81a2e0a28bb6eaa4d4850cb7a3259358105d7`; read-back confirmed `app_id: 4144849`.
