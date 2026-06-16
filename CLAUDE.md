# ProjectHana — agent operating conventions

These conventions apply to the main session **and** every workflow sub-agent in `.claude/agents/`.

## Prefer dedicated read-only tools over Bash for file inspection

Use the **Read**, **Grep**, and **Glob** tools — never shell `cat`, `head`, `tail`, `ls`, `find`,
or `grep` — to read files, search file contents, or list directories.

The dedicated tools never trigger a permission prompt, whereas the equivalent Bash commands cannot be
safely allowlisted (a wildcard like `Bash(cat *)` would also match `cat x; rm -rf y`, so they stay
prompted). Reaching for Read/Grep/Glob keeps the workflow flowing without the user having to approve
one-off inspection commands.

Reserve **Bash** for commands that have side effects or for tooling with no dedicated tool —
`git`, `gh`, `just`, `xcodebuild`, `direnv`, etc.
