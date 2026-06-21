# Hanahuac

[![CI](https://github.com/beyerja/ProjectHana/actions/workflows/ci.yml/badge.svg)](https://github.com/beyerja/ProjectHana/actions/workflows/ci.yml)

Hanahuac (*ha-na-wak*, "One World") is a personalized geography learning app for iOS and macOS combining Seterra-style interactive quizzes with SM-2 spaced repetition.

**Platform:** iOS 17+ / macOS 14+  
**Stack:** SwiftUI · SwiftData · MapKit · zero external dependencies

## Documentation
- [iCloud Progress Sync (CloudKit-ready)](docs/icloud-sync.md) — the sync architecture ships
  disabled by default; this doc lists the exact steps to enable live sync once a paid Apple
  Developer account exists.
- [Bot credentials (Hanahuac-Bot)](docs/bot-credentials.md) — how the bot's GitHub token is stored
  in the macOS Keychain, used via `scripts/gh-review-bot.sh`, scanned for by the pre-commit hook
  (`just install-hooks`), and rotated.
