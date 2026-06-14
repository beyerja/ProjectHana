# Story 003 — Required checks & branch-protection documentation

## Goal

Make the security scans actually gate merges, and document the security posture. Configure
required status checks / branch protection on `main` where the `gh` tooling allows, and
provide exact GitHub-UI instructions for anything that must be set by the repo owner.
Document the chosen blocking policy (secrets hard-block; CodeQL blocks on high-severity).

## Acceptance Criteria

- [ ] A `SECURITY.md` (or a `docs/security.md`) documents: which scanners run (CodeQL SAST,
      gitleaks secret scanning), why no dependency scanner is included (no dependencies),
      the blocking policy, and how to triage findings in the Security tab.
- [ ] The doc includes exact step-by-step instructions for the repo owner to mark the
      security check(s) as required status checks under `main` branch protection (Settings →
      Branches → branch protection rule), and to enable code-scanning merge protection so
      high-severity CodeQL alerts block merge.
- [ ] Where `gh` can configure branch protection non-interactively, attempt it and record
      the result; if it fails (e.g. permissions, or the check has not run yet so its context
      name is unknown), fall back to documented manual steps — do not block the workflow.
- [ ] The doc states the rationale for one-tool-per-concern and lists the pinned action
      versions.
- [ ] No `/nix/...` paths; no paid services referenced.

## Notes

- Depends conceptually on 001 and 002 existing (the check names come from those workflows),
  so implement it last. Touches only docs + optionally `gh api` branch-protection calls.
- Required-check context names: the CodeQL check appears as `CodeQL` (the analyze job) and
  the gitleaks check as the secret-scan job name. Capture the actual names from a real run
  before wiring them as required, or document how the owner selects them in the UI.
