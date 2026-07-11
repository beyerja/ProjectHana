**[nit, non-blocking] Server-side failure filter is available.**

The workflow-runs API accepts conclusion values in the `status` parameter, so `-f status=failure` returns only failed runs directly — smaller payloads, fewer pages, and the jq `select(.conclusion == "failure")` becomes redundant (harmless to keep as a belt-and-suspenders guard). Purely an efficiency/simplification suggestion; the current `status=completed` + client-side filter is functionally correct.
