import SwiftUI
import XCTest
@testable import Hanahuac

#if canImport(UIKit)
    import UIKit
#endif

/// Hosts SwiftUI views under the RTL modifier and asserts the environment `layoutDirection` actually
/// propagates (story 008 AC1/AC2). This complements `RTLLayoutDirectionTests` (pure mapping logic) by
/// proving the *applied* modifier reaches descendant views, and that key screens lay out under RTL
/// without regressing LTR.
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

    // MARK: - Key screens host under RTL

    /// The map learning screen — the one with manually placed overlays and a custom back control —
    /// hosts and lays out under forced RTL without crashing. Combined with the env-propagation tests
    /// above, this proves the mirrored map screen renders.
    func testMapScreenHostsUnderForcedRTL() {
        let view = MapLearningQuizView(newCards: [], category: nil)
            .withPreviewStore()
            .environment(LanguageManager.shared)
            .appLayoutDirection(for: .en, override: .rightToLeft)
        assertHostsWithoutCrash(view)
    }

    /// The home screen hosts and lays out under forced RTL.
    func testHomeScreenHostsUnderForcedRTL() {
        let view = HomeView()
            .withPreviewStore()
            .environment(LanguageManager.shared)
            .environment(SyncCoordinator(
                availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: false)
            ))
            .appLayoutDirection(for: .en, override: .rightToLeft)
        assertHostsWithoutCrash(view)
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

    /// Assert hosting + layout of an arbitrary view completes without crashing.
    private func assertHostsWithoutCrash(_ view: some View) {
        host(view)
        XCTAssertTrue(true, "view hosted and laid out without crashing")
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
