Non-blocking (nit): this `grep -v` is a no-op. Without `-E`, `|` is a literal character in BRE, so the pattern only excludes lines containing the literal string `CoreData|simctl|appintents` — i.e. nothing. The intended noise filter never filters. (Copied from the existing `test` recipe, which has the same latent issue — this new recipe is otherwise an improvement, since `set -euo pipefail` makes failures propagate, which `test` doesn't do.)

```suggestion
             | grep -v -E "CoreData|simctl|appintents"
```

Safe with `pipefail`: the `TEST SUCCEEDED`/`TEST FAILED` line always survives the filter, so `grep -v` can't empty the stream and exit 1. Fine to fix here or in a follow-up together with the `test` recipe.
