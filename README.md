# Hanahuac

[![CI](https://github.com/beyerja/ProjectHana/actions/workflows/ci.yml/badge.svg)](https://github.com/beyerja/ProjectHana/actions/workflows/ci.yml)

Hanahuac (*ha-na-wak*, "One World") is a personalized geography learning app for iOS and macOS combining Seterra-style interactive quizzes with SM-2 spaced repetition.

**Platform:** iOS 17+ / macOS 14+  
**Stack:** SwiftUI · SwiftData · MapKit · zero external dependencies

## Documentation
- [Releasing](docs/releasing.md) — the end-to-end release runbook: versioning + `just bump`, the
  bump-PR → annotated `v`-tag → release-workflow flow, every release quality gate and its local
  equivalent, and the switch-on steps for a future Apple Developer account.
- [Supported languages](docs/supported-languages.md) — the 21 in-app languages with native names +
  codes, the complete vs best-effort content contracts, the RTL set (ar, ur), how the two completeness
  gates enforce "no fallbacks", device-locale auto-selection, and the ODR delivery model.
- [iCloud Progress Sync (CloudKit-ready)](docs/icloud-sync.md) — the sync architecture ships
  disabled by default; this doc lists the exact steps to enable live sync once a paid Apple
  Developer account exists.
- [On-Demand Resource language packs](docs/odr-packaging.md) — how the non-base language packs
  (UI strings + geo-name JSON) ship as version-tagged On-Demand Resources, how to
  regenerate the geo packs, the release-tied versioning rule, and the async validation CI.
- [Bot credentials (Hanahuac-Bot)](docs/bot-credentials.md) — how the bot's GitHub token is stored
  in the macOS Keychain, used via `scripts/gh-review-bot.sh`, scanned for by the pre-commit hook
  (`just install-hooks`), and rotated.
