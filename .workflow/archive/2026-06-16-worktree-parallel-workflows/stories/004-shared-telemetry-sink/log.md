# Log — Shared telemetry sink with per-worktree tagging

break-tasks: DONE, 4 tasks
implement-story: DONE — agent-log.sh sink resolution via git-common-dir + feature tag; telemetry-summary.py --by-feature + untagged fallback. Commit e0c5890.
verify-story: DONE — verified from a real throwaway worktree that the edited script writes to the primary sink (count +1, no worktree-local sink) tagged feature:wt-final; just lint-sh, just telemetry, just telemetry-history all pass; default table unchanged. Removed self-test noise records from sink.
