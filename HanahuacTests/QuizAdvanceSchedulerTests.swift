import XCTest
@testable import Hanahuac

/// Regression coverage for the dismiss-while-advancing crash (story 002, AC2/AC3).
///
/// The four answer-driven quiz views schedule a delayed auto-advance through `QuizAdvanceScheduler`.
/// If the user exits the quiz (system back chevron / swipe-back) during the delay, the view's
/// `.onDisappear` cancels the owned `Task`. These tests pin the contract that a cancelled advance
/// runs NONE of its side-effects (no `session.advance()`, no `persistCardChanges()`, no
/// `recordSnapshot()`), so nothing touches the torn-down SwiftData environment after dismissal.
@MainActor
final class QuizAdvanceSchedulerTests: XCTestCase {
    /// When the sleep is cancelled (exit during the delay), the side-effects must NOT run.
    func testCancelledDuringSleep_skipsSideEffects() async {
        var sideEffectsRan = false
        let task = Task {
            await QuizAdvanceScheduler.run(
                afterNanoseconds: 5_000_000_000,
                sideEffects: { sideEffectsRan = true }
            )
        }
        // Cancel before the (long) sleep can complete — models the exit tap mid-advance.
        task.cancel()
        let didRun = await task.value
        XCTAssertFalse(didRun, "cancelled advance must report it did not run")
        XCTAssertFalse(sideEffectsRan, "side-effects must not run after cancellation")
    }

    /// When the surrounding Task is cancelled AFTER the sleep returns but before the side-effects,
    /// the explicit `Task.isCancelled` guard must still skip them. Modelled with an injected sleep
    /// that cancels the current Task instead of waiting.
    func testCancelledAfterSleep_skipsSideEffects() async {
        var sideEffectsRan = false
        let task = Task {
            await QuizAdvanceScheduler.run(
                afterNanoseconds: 1,
                sleep: { _ in
                    // Simulate the exit landing in the window between the sleep finishing and the
                    // side-effects running: the sleep "succeeds" but the Task is already cancelled.
                    withUnsafeCurrentTask { $0?.cancel() }
                },
                sideEffects: { sideEffectsRan = true }
            )
        }
        let didRun = await task.value
        XCTAssertFalse(didRun, "advance cancelled after wake must report it did not run")
        XCTAssertFalse(sideEffectsRan, "side-effects must not run when cancelled after the sleep")
    }

    /// The happy path: no cancellation → the sleep completes and the side-effects run exactly once.
    func testNotCancelled_runsSideEffectsOnce() async {
        var runCount = 0
        let didRun = await QuizAdvanceScheduler.run(
            afterNanoseconds: 1,
            sleep: { _ in /* no-op: complete immediately */ },
            sideEffects: { runCount += 1 }
        )
        XCTAssertTrue(didRun)
        XCTAssertEqual(runCount, 1, "an uncancelled advance must run its side-effects exactly once")
    }
}
