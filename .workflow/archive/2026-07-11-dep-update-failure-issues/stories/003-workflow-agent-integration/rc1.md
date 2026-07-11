**Blocking — nonexistent flag.** `gh issue close` has no `--comment-file` flag (verified against `gh issue close --help`: only `-c, --comment <string>` exists). An agent following this instruction gets `unknown flag: --comment-file` and the issue is never closed. The spec's own fallback covers this: comment first, then close —

```suggestion
     gh -R <owner/repo> issue comment <n> --body-file $RUN_TMPDIR/dep-issue-close.md
     gh -R <owner/repo> issue close <n>
```
