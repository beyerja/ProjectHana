# 005 — Language picker download progress, failure & retry UX

## Title
Surface ODR pack download progress, failure, and retry in the language picker, and reflect
bundled-vs-downloadable status

## Goal
Make the language picker drive and reflect the ODR download state machine (story 004): tapping
a not-yet-downloaded language shows visible download progress, a failure state with a retry
action, and on success switches the UI strings and geo names to that language. Base languages
(en, es-MX) are shown as always-available with no download.

## Background (current state)
- `Hanahuac/Views/Settings/LanguagePickerView.swift` lists `AppLocale.allCases` and sets
  `languageManager.current` on tap, with a checkmark for the selected language. No download or
  progress affordance exists.

## Acceptance Criteria
- [ ] The picker enumerates languages from the data-driven catalog (story 001) and shows each
      language's native display name.
- [ ] Selecting a not-yet-downloaded (downloadable) language triggers the lazy ODR download via
      the provider and shows VISIBLE progress (e.g. a determinate progress indicator driven by
      the state machine's fractional progress).
- [ ] On download success, the picker selects the language and the app's UI strings and geo
      names switch to it.
- [ ] On download failure, the picker shows a clear failure state with a RETRY affordance that
      re-issues the download.
- [ ] Base/bundled languages (en, es-MX) appear as immediately selectable with no download
      affordance; already-downloaded packs appear as available (no re-download prompt).
- [ ] Selecting a language while offline with its pack absent degrades gracefully (fallback
      chain) and communicates the unavailable/failed state rather than crashing.
- [ ] New/updated view-model or presentation tests cover the picker's rendering of the
      download states (idle/available, downloading+progress, failed+retry) driven by the state
      machine, without live network.

## Out of Scope
- The ODR mechanism/state machine itself (story 004 — consumed here).
- ODR build/packaging config + validation CI (story 006).
- Adding new languages.
