**"Supported actions exercised" table inherits the same off-by-one (documentation, non-blocking).**

`tap by identifier` lists `013`, but artifact 013 is a `wait` — the third identifier-tap (`home.settings`) is artifact **014**. Likewise `wait` lists `013, 014` where it should reference the wait artifacts after the off-by-one correction. Please reconcile this table with the corrected step index above so the action→step references are accurate (e.g. `tap by identifier` → 003, 006, 014).
