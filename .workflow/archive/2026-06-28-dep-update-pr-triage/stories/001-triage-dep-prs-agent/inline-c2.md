**BLOCKING — Step 2b runs unconditionally for UNKNOWN-skipped PRs**

Step 2a's skip instruction says "continue to the next PR" when `mergeable` is still `UNKNOWN` after retry. However, step 2b's heading says "For **all** dep PRs (regardless of `mergeable` status)". An agent following the spec linearly will execute 2b (checkout the dep branch) on a PR that was already added to the skipped list in 2a, potentially checking out, testing, and trying to merge a PR flagged as unresolvable.

The "regardless of mergeable status" clause was added to fix the Round 1 finding about MERGEABLE PRs not being tested. It now over-applies and overrides the UNKNOWN skip. The clause needs an explicit carve-out: "For all dep PRs **that were not skipped in 2a** (i.e., `MERGEABLE` or `CONFLICTING`)".
