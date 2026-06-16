# Log — Build/test isolation in the justfile

break-tasks: DONE, 3 tasks
implement-story: DONE — justfile `wt`/`sim` vars; test/build-mac/install/build-sim/install-sim/boot-sim parameterized. Verified via just --evaluate + --dry-run that empty wt == legacy paths and wt=feat-x suffixes. just lint-sh passed. Commit 0ab885f.
verify-story: DONE — all 5 criteria confirmed by dry-run rendering (defaults unchanged; isolation applied when set; single driving var; lint clean).
