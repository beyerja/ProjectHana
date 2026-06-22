## Goal

The app previously had zero accessibility modifiers. This story makes the highest-traffic
interactive surface — the non-map quiz flows and their shared chrome — usable with VoiceOver and
Dynamic Type. It is the first of two accessibility stories (map-quiz annotations are story 005).

## Summary of changes

- Added meaningful VoiceOver labels/hints/values to interactive controls in the text quiz flows
  (CapitalQuizView, NameFeatureQuizView, and other TextQuizSession-driven views); answer
  fields/buttons announce their purpose and state.
- Exposed each choice in the multiple-choice quiz flow (MultipleChoiceQuizView) as a distinct,
  labeled accessibility element, conveying correct/incorrect/selected state via label/value/trait
  rather than color alone.
- Surfaced prompts, progress, and results to VoiceOver in the learning quiz flow (LearningQuizView)
  and the quiz summary (QuizSummaryView) with appropriate labels/values.
- Ensured informational/result text in these flows is reachable and read in a sensible order.
- Verified Dynamic Type scaling across these flows (scalable text styles, no clipping/truncation of
  critical content at larger accessibility sizes) and fixed concrete issues found.
- Added `a11y.*` localization keys across all 6 locales plus a test verifying they resolve.

Purely additive view modifiers and localization; no new dependencies. MapKit annotation
accessibility remains out of scope (story 005).

## Test plan

- [ ] Project builds
- [ ] Localization-resolution test for the new `a11y.*` keys passes across all 6 locales
- [ ] VoiceOver reads labels/hints/values/state in text, multiple-choice, and learning quiz flows
- [ ] Dynamic Type at large accessibility sizes does not clip/truncate critical content

🤖 Generated with [Claude Code](https://claude.com/claude-code)
