import XCTest

/// End-to-end UI assertions that the app mirrors under a forced right-to-left layout direction
/// (story 008 AC1/AC2/AC3), plus an LTR control proving the existing layout is unaffected (AC5).
///
/// The app is launched with `-HANA_FORCE_RTL`, the launch-time override the RTL infrastructure reads
/// at the root (`LayoutDirectionOverride`), so RTL is exercised BEFORE Arabic/Urdu content exists and
/// on an LTR host — exactly what the greenfield infrastructure story needs.
final class RTLLayoutUITests: XCTestCase {
    private let timeout: TimeInterval = 15

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Element-layout + reading-order assertion under RTL (AC2/AC3): under forced RTL the home
    /// toolbar's `.topBarTrailing` settings gear mirrors to the LEADING (left) edge; under LTR it sits
    /// on the trailing (right) edge. Asserting the same control lands on opposite sides of the screen
    /// midline between the two directions proves the navigation chrome (and thus the trailing-edge
    /// reading position) actually mirrors — it fails if RTL were not applied. The *reading order* that
    /// SwiftUI derives from `\.layoutDirection` is asserted directly at the unit level by
    /// `RTLEnvironmentHostingTests` (the environment value reaches the view tree); this is the
    /// end-to-end element-layout half of that guarantee.
    func testHomeToolbarMirrorsUnderRTL() {
        let rtlFraction = settingsGearMidXFraction(forceRTL: true)
        let ltrFraction = settingsGearMidXFraction(forceRTL: false)

        // The same control lands on opposite sides of the screen midline between the two directions.
        XCTAssertLessThan(rtlFraction, 0.5, "RTL: settings gear must mirror to the left half")
        XCTAssertGreaterThan(ltrFraction, 0.5, "LTR: settings gear stays on the right half")
        XCTAssertLessThan(
            rtlFraction, ltrFraction,
            "the gear must move leftward when the layout flips to RTL"
        )
    }

    /// LTR regression control: the settings screen + language picker open and render under the default
    /// (LTR) direction unchanged — the existing layout is unaffected by the RTL infrastructure.
    func testSettingsAndPickerRenderUnderLTR() {
        let app = launch(forceRTL: false)
        let gear = app.buttons["home.settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: timeout))
        gear.tap()

        let language = app.cells["settings.language"].firstMatch
        let languageButton = app.buttons["settings.language"].firstMatch
        let target = language.exists ? language : languageButton
        XCTAssertTrue(target.waitForExistence(timeout: timeout), "language entry should be reachable")
        target.tap()
        attachScreenshot(name: "ltr-picker")
    }

    // MARK: - Helpers

    /// Launch the app, optionally forcing RTL via the launch argument the infrastructure reads.
    private func launch(forceRTL: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        if forceRTL {
            app.launchArguments.append("-HANA_FORCE_RTL")
        }
        app.launch()
        return app
    }

    /// The settings gear's mid-x as a fraction of the window width (0 = left edge, 1 = right edge).
    private func settingsGearMidXFraction(forceRTL: Bool) -> CGFloat {
        let app = launch(forceRTL: forceRTL)
        let gear = app.buttons["home.settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: timeout), "settings gear should exist")
        let window = app.windows.firstMatch
        let midX = gear.frame.midX
        attachScreenshot(name: forceRTL ? "rtl-home" : "ltr-home")
        return window.frame.width > 0 ? midX / window.frame.width : 0
    }

    /// Attach a screenshot artifact so the RTL/LTR rendering is captured in the test report.
    private func attachScreenshot(name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
