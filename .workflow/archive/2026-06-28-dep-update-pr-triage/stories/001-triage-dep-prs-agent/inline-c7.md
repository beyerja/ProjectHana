**BLOCKING — `gh pr checks --watch` immediately after close/reopen with no sleep**

`gh pr checks --watch --fail-fast` is called immediately after `gh pr reopen`. If CI checks have not registered yet (common — GitHub takes a few seconds to dispatch workflows), `--watch` exits immediately with zero checks, which the tool treats as success. The agent then falls through the "no runs within ~30s" fallback incorrectly (it has no way to know if 30s have passed).

CLAUDE.md explicitly says: "If the checks haven't registered yet, do a single `sleep <n>` then one `--watch`."

Fix: add `sleep 15` (matching the pattern in `wait-for-ci.md`) between the reopen and the `--watch` call:
```sh
gh -R <owner/repo> pr reopen <number>
sleep 15
gh pr checks <number> -R <owner/repo> --watch --fail-fast
```
