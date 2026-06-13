## Tasks

- [x] 001: Add `@State private var isPinching = false` to MapQuizView and MapLearningQuizView; attach `.simultaneousGesture(MagnificationGesture().onChanged { _ in isPinching = true }.onEnded { _ in isPinching = false })` to the Map, and gate each pin Button action with `guard !isPinching else { return }` (in addition to the existing `!isAdvancing` guard)
- [x] 002: Update `CountryPinView` button `.disabled(...)` in both views to also include `isPinching` in the disabled condition
- [x] 003: Run `just test` and fix any failures
