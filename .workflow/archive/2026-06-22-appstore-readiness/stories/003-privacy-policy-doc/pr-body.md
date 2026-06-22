## Goal

App Store Connect requires a hosted privacy-policy URL. This story authors the policy text in-repo
(`docs/privacy-policy.md`) so it can be published as a static page and linked from App Store Connect.
The policy factually reflects that the app collects and transmits no data.

## Summary of changes

- Add `docs/privacy-policy.md`, an in-repo privacy policy suitable to host and reference from App
  Store Connect.
- States the app collects/transmits **no** data: fully offline, no network/location/camera/photo/
  notification access, no tracking, nothing shared with third parties, no third-party SDKs/analytics.
- Notes all user data (learning progress, preferences) stays on-device in local storage, and that
  iCloud/CloudKit sync is currently disabled (consistent with the `CLOUDKIT_SYNC` gate).
- Structured as a clean static page: clear sections, last-updated date, and a contact line.

Documentation-only change — no code or `project.yml` changes.

## Test plan

- [x] `docs/privacy-policy.md` exists and is authored in-repo.
- [x] Policy accurately states no data is collected/transmitted; app is fully offline with no
      tracking and no third-party sharing.
- [x] Policy notes on-device-only storage and that CloudKit sync is currently disabled.
- [x] Document has clear sections, a last-updated date, and a contact line suitable for hosting.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
