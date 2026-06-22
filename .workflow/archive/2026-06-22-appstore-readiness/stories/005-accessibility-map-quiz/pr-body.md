## Goal

Make the MapKit map-quiz annotations and surrounding chrome accessible to VoiceOver, and verify
Dynamic Type for the non-map chrome. The map-quiz annotations were previously invisible to VoiceOver;
this is the map-specific accessibility story, split from 004 because MapKit accessibility is a distinct
technical surface.

## Summary of changes

- **Accessible map-pin annotations** (`MapFeaturePinView` in `MapFeatureRendering.swift`): added
  `accessibilityElement(children: .ignore)`, a label (feature name), a state-driven value
  (not-answered / correct / incorrect) so correct/incorrect is conveyed without color alone, and the
  `.isButton` trait. Both map views inherit the shared pin.
- **Annotation buttons wired for VoiceOver** in `MapQuizView` and `MapLearningQuizView`: added the
  `a11y.map.pin.hint` hint that disappears once answered, with the disabled/answered state reflected to
  VoiceOver.
- **Combined prompt/progress banners**: collapsed the stacked prompt Texts into a single sensible
  VoiceOver element (prompt label + feature name as label, progress/streak as value) in both views, so
  order and content are spoken clearly rather than as raw fragments.
- **Feedback announcements**: the colored correct/incorrect feedback banner now announces success/
  failure plus the revealed correct feature name, so the result is not conveyed by banner color alone.
- **Dynamic Type reflow** for non-map chrome (prompt/feedback banners, exit toolbar button,
  completion view) so text is not clipped at the largest accessibility sizes. The MapKit map surface
  itself is exempt (tiles do not scale with Dynamic Type).
- **Localization**: 4 new `a11y.*` keys (map pin hint, prompt label, map progress, streak) added to
  `en`, `es-MX`, `de`, `ko`, `fr`; `nah` resolves via the fallback chain per the downloadable-pack
  pattern. Existing feedback/state keys are reused, not duplicated.
- **Tests**: extended `QuizAccessibilityStringsTests` to cover the new keys (non-raw, non-empty
  resolution per locale) and added the parameterized keys to the format-specifier checks.

SwiftUI/MapKit only — no new dependencies, no signing/capabilities/usage-description changes.

## Test plan

- [ ] `QuizAccessibilityStringsTests` passes (new keys resolve for every locale via the fallback chain)
- [ ] VoiceOver reads each map pin's name and correct/incorrect state
- [ ] VoiceOver reads the prompt + progress/streak as a single sensible element
- [ ] Feedback result is announced (not color-only)
- [ ] Non-map chrome is not clipped at AX5 (`.accessibilityExtraExtraExtraLarge`)
