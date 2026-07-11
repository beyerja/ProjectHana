**[non-blocking] Quote `{{part}}` like the sibling recipes do.**

With `set shell := ["bash", "-c"]`, the unquoted `{{part}}` is interpolated raw into the shell line, so an argument containing spaces or shell metacharacters is word-split / expanded by bash before argparse ever sees it (e.g. `just bump '$(…)'` would be executed by the shell). The other parameterized recipes in this justfile already quote their interpolations (`'{{sim}}'`, `'{{script}}'`, `"{{path}}"`); quoting here keeps validation where it belongs — in the script's `choices=("major", "minor", "patch")`.

```suggestion
    python3 scripts/bump-version.py '{{part}}'
```

Low severity (the invoker is only exposed to their own input), so this does not block approval.
