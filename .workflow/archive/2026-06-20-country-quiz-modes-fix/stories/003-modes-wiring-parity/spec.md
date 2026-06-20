# Story 003 — Home wiring, mode parity, and L10n

## Title
Wire the new "Name that feature" mode into every category, give both text modes new+pending parity, and
localize all strings

## Goal
Surface the new map-pin "Name that feature" quiz on the home screen for all four categories, remove the
old capital-based "Name the Country" reverse mode, and give the two text-based modes ("Type the Capital"
and "Name that feature") full new+pending parity with the rest of the app. Localize every new/changed UI
string across all shipped locales.

## Acceptance Criteria
- [ ] `HomeQuizMode`: the old `nameCountry` (capital→country) case is replaced by a `nameFeature`
      map-pin mode; both `nameFeature` and `typeCapital` return `supportsNew = true`. Icons/colors/title
      keys updated accordingly.
- [ ] Home screen: the "Name that feature" mode appears under all four categories (countries, rivers,
      mountains, seas). "Type the Capital" stays Countries-only. Tiles show New and Pending counts and
      the all-done state for these modes, like the existing modes.
- [ ] Navigation/routing (`HomeView.directQuizView` + `PilePickerView`): the new pile of each text mode
      routes to the learning variant and the pending pile to the due variant of the appropriate view
      (`NameFeatureQuizView` for `nameFeature`; the capital quiz for `typeCapital`, which now needs a
      new-pile learning path or reuse of the existing learning flow for capitals). The old
      `CapitalQuizView(mode: .countryOfCapital)` route is removed.
- [ ] "Type the Capital" retains its capital-of-country mechanic and gains a working new pile (seeding +
      advancing new country cards through SM-2 + progress recording), consistent with goal 1 of the
      feature spec.
- [ ] All new/changed UI strings (mode titles, prompt "Name this …", text-field placeholder, feedback,
      nav titles, nothing-due title/desc) have keys present for en, fr, de, es-MX, ko, nah, consistent
      with the existing L10n bundle and whatever key-coverage tests exist.
- [ ] The app builds; existing tests pass; and a test asserts the home mode list offers `nameFeature`
      for every category and that `nameFeature`/`typeCapital` report `supportsNew == true`.

## Notes
Depends on stories 001 (sessions) and 002 (view). If `typeCapital`'s new-pile learning path requires a
small capital-specific learning session, add it here reusing the existing learning mechanic; do not
duplicate SM-2/graduation logic.
