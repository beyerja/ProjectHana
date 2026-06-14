# Story 005 — In-repo documentation: how to enable live iCloud sync later

## Title
Document the exact steps to turn on live CloudKit sync once a paid Apple Developer account exists

## Goal
Capture, in-repo, the precise, ordered, verifiable steps to go from today's
CloudKit-ready-but-disabled state to live cross-device sync — so a future maintainer (with a
paid account) can flip it on without re-deriving the architecture. This is the artifact that
makes the "single flip" real and auditable.

## Acceptance Criteria
- [ ] A doc file (e.g. `docs/icloud-sync.md`, linked from README if a README exists) that
      lists, in order:
      1. Apple Developer Program enrollment (paid) prerequisite.
      2. Creating the iCloud CloudKit container (container identifier convention,
         e.g. `iCloud.com.hanahuac.app`).
      3. The exact entitlements to add to `project.yml` (CloudKit / iCloud Documents as
         applicable, `NSUbiquitousKeyValueStore` key-value entitlement, the container id) and
         where they live in the targets block — shown as a copy-pasteable snippet, but
         explicitly NOT applied to the committed `project.yml`.
      4. Background Modes (remote notifications) needed for CloudKit push, and any
         `Info.plist`/capability settings.
      5. The single flag to flip (the `CLOUDKIT_SYNC` compile condition / coordinator flag from
         Story 003) and how to set it (build setting / xcconfig / scheme).
      6. How to regenerate the Xcode project (`just generate` / xcodegen) after editing
         `project.yml`.
      7. How to verify post-enable (sign into iCloud on two devices, observe convergence,
         dedup-by-factID behavior), with the caveat that this cannot be done without the paid
         account.
- [ ] The doc explicitly states the current shipped state: CloudKit path disabled by default,
      local-only behavior, zero external dependencies, last-writer-wins conflict policy.
- [ ] The doc names the exact files/types involved (coordinator, flag, syncable stores,
      `ReviewCard` compatibility, dedup-by-factID) so the wiring is discoverable.
- [ ] No code or `project.yml` entitlement changes are made by this story — documentation only
      (plus optional README link). Build + CI unaffected.

## Out of Scope
- Actually enabling anything.
- Code changes (covered by Stories 001–004).

## Notes
- Pull the concrete file/flag/type names from whatever Stories 001–004 actually produced;
  do not invent names that don't exist in the tree.
- Verify GitHub Actions / tooling references are accurate; don't assume versions.
