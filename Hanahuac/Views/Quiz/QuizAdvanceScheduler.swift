import Foundation

/// Encapsulates the auto-advance "wait, then run side-effects" step shared by the four answer-driven
/// quiz views (Multiple Choice, Learning, Map, Map-Learning).
///
/// The quiz screens are pushed onto `HomeView`'s `NavigationStack`. After the user answers, a delayed
/// advance is scheduled so the correct/incorrect feedback stays on screen for ~1–2s. If the user
/// exits (system back chevron or swipe-back) DURING that delay, the view is dismissed and its
/// environment — including the SwiftData-backed `CardStore` / `ProgressStatsStore` — is torn down.
/// An unstructured detached `Task` that woke after the sleep and called `session.advance()` /
/// `persistCardChanges()` / `recordSnapshot()` on that now-dead context caused a use-after-teardown
/// crash (the dismiss-while-advancing race, AC2).
///
/// `run` performs the sleep and then runs `sideEffects` ONLY if the owning `Task` has not been
/// cancelled. Callers own the returned/assigned `Task` in `@State` and cancel it from `.onDisappear`,
/// so exiting mid-advance is a guaranteed no-op: no advance, no persist, no snapshot after teardown.
enum QuizAdvanceScheduler {
    /// Sleep for `nanoseconds`, then run `sideEffects` unless the surrounding `Task` was cancelled.
    ///
    /// Returns `true` if `sideEffects` ran, `false` if the wait was cancelled (so the side-effects
    /// were skipped). The boolean exists so unit tests can assert the cancellation contract without a
    /// live view environment.
    @discardableResult
    @MainActor
    static func run(
        afterNanoseconds nanoseconds: UInt64,
        sleep: (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) },
        sideEffects: @MainActor () -> Void
    ) async -> Bool {
        // A cancelled sleep throws CancellationError; a cancelled-after-wake Task is caught by the
        // explicit isCancelled check. Either path must skip the side-effects.
        do {
            try await sleep(nanoseconds)
        } catch {
            return false
        }
        guard !Task.isCancelled else {
            return false
        }
        sideEffects()
        return true
    }
}
