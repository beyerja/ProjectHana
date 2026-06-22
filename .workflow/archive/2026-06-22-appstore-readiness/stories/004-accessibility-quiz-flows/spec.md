# 004 — Accessibility: quiz flows (VoiceOver + Dynamic Type)

## Title
Add VoiceOver labels/hints/values and verify Dynamic Type across the text/multiple-choice/learning quiz flows

## Goal
The app currently has ZERO accessibility modifiers. This story covers the highest-traffic
interactive surface: the non-map quiz flows and their shared chrome. It is the first of two
accessibility stories (map-quiz annotations are story 005).

## Acceptance Criteria
Traceable to feature.md (Accessibility AC, scoped to quiz flows):

- [ ] Interactive controls in the text quiz flows (CapitalQuizView, NameFeatureQuizView,
      TextQuizSession-driven views) carry meaningful VoiceOver labels and, where helpful, hints;
      answer fields/buttons announce their purpose and state.
- [ ] The multiple-choice quiz flow (MultipleChoiceQuizView) exposes each choice as a distinct,
      labeled accessibility element; correct/incorrect/selected state is conveyed to VoiceOver
      (label/value/trait, not color alone).
- [ ] The learning quiz flow (LearningQuizView) and the quiz summary (QuizSummaryView) expose
      prompts, progress, and results to VoiceOver with appropriate labels/values.
- [ ] Informational/result text in these flows is reachable and read in a sensible order
      (no important content invisible to VoiceOver).
- [ ] Dynamic Type scaling is verified in these flows: text uses scalable styles and layouts do
      not clip/truncate critical content at larger accessibility text sizes; concrete issues found
      are fixed. (feature.md AC: verify Dynamic Type)

## Notes / Constraints
- SwiftUI/SwiftData/MapKit only; add no dependencies. (feature.md Constraints)
- Map-quiz MapKit annotation accessibility is explicitly OUT of scope here — see story 005.
- Purely additive view modifiers; independent of all other stories and builds on its own.
