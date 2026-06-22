# 003 — Privacy policy document

## Title
Author an in-repo privacy policy suitable to host and reference from App Store Connect

## Goal
App Store Connect requires a hosted privacy-policy URL. Author the policy text in-repo so it can
be published and linked. It must accurately reflect that the app collects and transmits no data.

## Acceptance Criteria
Traceable to feature.md:

- [ ] A privacy-policy document is authored in-repo (e.g. `docs/privacy-policy.md`). (feature.md
      AC: privacy-policy document)
- [ ] The policy accurately states the app collects/transmits NO data: it is fully offline
      (no network/location/camera/photo/notification access), does no tracking, and shares nothing
      with third parties. (feature.md AC + Constraints: fully offline)
- [ ] The policy notes that all user data (learning progress, preferences) stays on-device in
      local storage, and that iCloud/CloudKit sync is currently disabled. (consistent with the
      CLOUDKIT_SYNC gate; feature.md Out of Scope leaves the gate as-is)
- [ ] The document is structured/clean enough to host as a static page and reference from App
      Store Connect (clear sections, last-updated date, contact line).

## Notes / Constraints
- Documentation-only story; no code or `project.yml` changes. Fully independent of all others.
- Do not claim data collection the app does not perform; keep it factual.
