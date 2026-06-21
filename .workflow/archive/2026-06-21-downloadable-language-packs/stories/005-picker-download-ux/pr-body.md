## Goal

Make the language picker drive and reflect the ODR download state machine (story 004): tapping a
not-yet-downloaded language shows visible download progress, a failure state with a retry action, and
on success switches the app's UI strings and geo names to that language. Base/bundled languages
(en, es-MX) appear as always-available with no download affordance.

## Summary of changes

- Picker now enumerates languages from the data-driven catalog (story 001) and shows each language's
  native display name.
- Selecting a downloadable language triggers the lazy ODR download via the provider and surfaces
  VISIBLE determinate progress driven by the state machine's fractional progress (story 004).
- On download success the picker selects the language and the app's UI strings and geo names switch
  to it.
- On download failure the picker renders a clear failure state with a RETRY affordance that re-issues
  the download.
- Base/bundled languages and already-downloaded packs render as immediately available with no
  re-download prompt.
- Offline selection of a language whose pack is absent degrades gracefully via the fallback chain and
  communicates the unavailable/failed state rather than crashing.
- Launch reconciliation fix: addresses the `didSet`-on-init carry-over surfaced in story 004's review,
  so the picker's reflected state is correct on cold start.
- New/updated view-model/presentation tests cover the picker's rendering of the download states
  (idle/available, downloading+progress, failed+retry) without live network.

## Acceptance criteria (from spec.md)

- [x] Picker enumerates languages from the data-driven catalog and shows native display names.
- [x] Selecting a downloadable language triggers the lazy ODR download and shows visible progress.
- [x] On success, the picker selects the language and UI strings + geo names switch to it.
- [x] On failure, the picker shows a clear failure state with a RETRY affordance.
- [x] Base/bundled (en, es-MX) and already-downloaded packs are immediately selectable, no re-download.
- [x] Offline selection with pack absent degrades gracefully and communicates the state, no crash.
- [x] View-model/presentation tests cover idle/available, downloading+progress, failed+retry states
      without live network.

## Test plan

- [ ] Run the view-model/presentation test suite (state rendering: idle/available, downloading, failed+retry).
- [ ] Manually select a downloadable language and observe determinate progress, then success switching strings + geo names.
- [ ] Force a download failure and confirm the failure state + retry re-issues the download.
- [ ] Confirm en / es-MX show as immediately selectable with no download affordance.
- [ ] Cold-launch with a downloaded pack and confirm reflected state is correct (no didSet carry-over).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
