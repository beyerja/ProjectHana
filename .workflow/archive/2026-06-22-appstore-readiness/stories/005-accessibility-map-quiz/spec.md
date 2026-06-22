# 005 — Accessibility: map-quiz annotations (VoiceOver + Dynamic Type)

## Title
Make MapKit map-quiz annotations and surrounding chrome accessible to VoiceOver, with Dynamic Type

## Goal
The MapKit map-quiz annotations are currently invisible to VoiceOver (the spec calls this out
specifically). This is the second, more specialized accessibility story, separated from 004
because map/MapKit accessibility is a distinct technical surface.

## Acceptance Criteria
Traceable to feature.md (Accessibility AC, scoped to the map quiz):

- [ ] MapKit annotations in the map-quiz views (MapQuizView, MapLearningQuizView,
      MapFeatureRendering) expose accessibility labels/values so VoiceOver users can identify and
      interact with each annotation (currently invisible to VoiceOver). (feature.md AC: map-quiz
      annotations invisible to VoiceOver)
- [ ] Interactive elements of the map quiz (prompts, answer entry, controls, region/zoom chrome)
      carry VoiceOver labels/hints and convey selected/correct/incorrect state without relying on
      color alone.
- [ ] The map-quiz prompt/result text and progress are reachable by VoiceOver in a sensible order.
- [ ] Dynamic Type is verified for the map quiz's non-map text/controls; concrete clipping or
      truncation issues at large accessibility sizes are fixed. (feature.md AC: verify Dynamic Type)

## Notes / Constraints
- SwiftUI/SwiftData/MapKit only; add no dependencies. (feature.md Constraints)
- Independent of 004 (different files/surface); additive modifiers; builds on its own.
