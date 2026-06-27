import SwiftUI
import XCTest
@testable import Hanahuac

#if canImport(UIKit)
    import UIKit
#endif

/// Hosts a lightweight probe under the RTL modifier and asserts the environment `layoutDirection`
/// actually propagates to descendant views (story 008 AC1/AC2). This complements
/// `RTLLayoutDirectionTests` (pure mapping logic) by proving the *applied* modifier reaches the
/// subtree. Real-screen mirroring under RTL (home/settings/picker) is verified end-to-end by
/// `RTLLayoutUITests`, which launches the actual app — that is the right layer for full-screen layout,
/// so this unit test deliberately hosts only a minimal probe (hosting heavy real screens in a unit
/// test is environment-fragile on the CI Catalyst host).
@MainActor
final class RTLEnvironmentHostingTests: XCTestCase {
    /// A probe that copies the inherited `\.layoutDirection` into a shared sink the test can read once
    /// SwiftUI has resolved the environment for the hosted tree.
    private struct LayoutDirectionProbe: View {
        @Environment(\.layoutDirection) private var layoutDirection
        let sink: DirectionSink

        var body: some View {
            Color.clear
                .onAppear { sink.value = layoutDirection }
        }
    }

    /// Reference-type sink so the value escapes the value-type probe.
    private final class DirectionSink {
        var value: LayoutDirection?
    }

    // MARK: - Modifier propagation

    /// Applying `.appLayoutDirection(for: .ar)` (an RTL language) propagates `.rightToLeft` to the
    /// hosted subtree — proving the selected RTL language drives the whole app's layout direction.
    func testSelectedRTLLanguagePropagatesRightToLeft() {
        let resolved = resolveDirection {
            LayoutDirectionProbe(sink: $0)
                .appLayoutDirection(for: .ar, override: nil)
        }
        XCTAssertEqual(resolved, .rightToLeft)
    }

    /// Urdu likewise propagates `.rightToLeft`.
    func testUrduPropagatesRightToLeft() {
        let resolved = resolveDirection {
            LayoutDirectionProbe(sink: $0)
                .appLayoutDirection(for: .ur, override: nil)
        }
        XCTAssertEqual(resolved, .rightToLeft)
    }

    /// An LTR language (English) keeps `.leftToRight` — the LTR regression guard at the env level.
    func testLTRLanguageStaysLeftToRight() {
        let resolved = resolveDirection {
            LayoutDirectionProbe(sink: $0)
                .appLayoutDirection(for: .en, override: nil)
        }
        XCTAssertEqual(resolved, .leftToRight)
    }

    /// The launch-time force-RTL override flips an LTR language to `.rightToLeft`, so RTL is
    /// exercisable in tests / the walkthrough before ar/ur content exists.
    func testForceRTLOverrideFlipsLTRLanguage() {
        let resolved = resolveDirection {
            LayoutDirectionProbe(sink: $0)
                .appLayoutDirection(for: .en, override: .rightToLeft)
        }
        XCTAssertEqual(resolved, .rightToLeft)
    }

    // MARK: - Helpers

    /// Host a probe-bearing view, pump a run loop turn so SwiftUI resolves the environment + fires
    /// `onAppear`, and return the captured layout direction.
    private func resolveDirection(
        @ViewBuilder _ build: (DirectionSink) -> some View
    ) -> LayoutDirection? {
        let sink = DirectionSink()
        let view = build(sink)
        host(view)
        return sink.value
    }

    /// Mount a view in a hosting controller, force layout, and pump the run loop so lifecycle events
    /// (`onAppear`) fire. No-op return on platforms without UIKit (tests run on the iOS simulator).
    private func host(_ view: some View) {
        #if canImport(UIKit)
            let controller = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = controller
            window.isHidden = false
            window.layoutIfNeeded()
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        #endif
    }
}
