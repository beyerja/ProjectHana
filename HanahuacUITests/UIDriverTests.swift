import XCTest

/// The single generic, data-driven UI driver. It launches the Hanahuac app, ALWAYS emits an
/// initial dump + screenshot (step 000), then executes each action from the loaded script in order,
/// emitting a `NNN-step.png` + `NNN-step.json` artifact pair after EVERY step.
///
/// Element targeting is by accessibility LABEL first, falling back to `identifier` when one is
/// supplied — so the driver works before story 002 introduces explicit accessibility identifiers.
/// An empty or missing script is not an error: the app still launches and the initial artifacts are
/// produced.
final class UIDriverTests: XCTestCase {
    /// How long to wait for a targeted element to appear before acting on it.
    private let elementTimeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Drive the app from the configured action script (or just produce the initial artifacts).
    func testRunUIScript() {
        let app = XCUIApplication()
        app.launch()

        let recorder = UIWalkthroughRecorder()
        var stepIndex = 0

        // Step 000: always capture the initial state before doing anything.
        record(app: app, recorder: recorder, index: stepIndex)
        stepIndex += 1

        let steps = UIActionScriptLoader.load()
        for step in steps {
            perform(step, in: app)
            record(app: app, recorder: recorder, index: stepIndex)
            stepIndex += 1
        }
    }

    /// Capture and persist the artifact pair for the current step.
    private func record(app: XCUIApplication, recorder: UIWalkthroughRecorder, index: Int) {
        let screenshot = XCUIScreen.main.screenshot()
        recorder.record(index: index, app: app, screenshot: screenshot)
    }

    /// Execute one action against the app. Unresolvable targets are skipped (logged) rather than
    /// failing the test, so artifact collection continues across the whole script.
    private func perform(_ step: UIActionStep, in app: XCUIApplication) {
        switch step.action {
        case .tap:
            tap(step, in: app)
        case .typeText:
            typeText(step, in: app)
        case .mapTap:
            mapTap(step, in: app)
        case .swipe, .scroll:
            swipe(step, in: app)
        case .pinch:
            pinch(step, in: app)
        case .wait:
            wait(step)
        case .dumpTree, .screenshot:
            // Both are realized by the artifact emission that follows every step; no extra action.
            break
        }
    }

    /// Tap the element resolved by label/identifier, if any.
    private func tap(_ step: UIActionStep, in app: XCUIApplication) {
        guard let element = resolveElement(step, in: app) else {
            return
        }
        if element.waitForExistence(timeout: elementTimeout) {
            element.tap()
        }
    }

    /// Type into the resolved element (falling back to the app's first text field).
    private func typeText(_ step: UIActionStep, in app: XCUIApplication) {
        guard let text = step.text else {
            return
        }
        let element = resolveElement(step, in: app) ?? app.textFields.firstMatch
        if element.waitForExistence(timeout: elementTimeout) {
            element.tap()
            element.typeText(text)
        }
    }

    /// Tap a normalized (0...1) coordinate within the app frame — used for map interactions where
    /// there is no addressable accessibility element.
    private func mapTap(_ step: UIActionStep, in app: XCUIApplication) {
        let normX = step.x ?? 0.5
        let normY = step.y ?? 0.5
        let coordinate = app.coordinate(
            withNormalizedOffset: CGVector(dx: normX, dy: normY)
        )
        coordinate.tap()
    }

    /// Swipe/scroll the resolved element (or the whole app) in the requested direction.
    private func swipe(_ step: UIActionStep, in app: XCUIApplication) {
        let element = resolveElement(step, in: app) ?? app
        switch step.direction ?? .up {
        case .up:
            element.swipeUp()
        case .down:
            element.swipeDown()
        case .left:
            element.swipeLeft()
        case .right:
            element.swipeRight()
        }
    }

    /// Pinch the resolved element (or the whole app) to zoom. `scale` is required (< 1 zooms out,
    /// > 1 zooms in) — the step is skipped when it is absent. A label/identifier-targeted element is
    /// waited for; if it never appears the step is skipped (no crash, no failure) so artifact
    /// collection continues.
    ///
    /// `XCUIElement.pinch(withScale:velocity:)` requires `scale > 0` AND a non-zero velocity whose
    /// sign matches the scale: NEGATIVE for zoom out (`scale < 1`) and POSITIVE for zoom in
    /// (`scale > 1`); a non-positive scale or zero/mismatched velocity raises
    /// `NSInvalidArgumentException`. So a `pinch` whose `scale` is absent or non-positive is skipped
    /// (same as other unresolvable steps), and a nil OR zero `velocity` is replaced with a
    /// correctly-signed default derived from the scale; an explicit non-zero `velocity` is respected.
    private func pinch(_ step: UIActionStep, in app: XCUIApplication) {
        guard let scale = step.scale, scale > 0 else {
            return
        }
        let resolvedVelocity = step.velocity ?? 0
        let velocity = resolvedVelocity == 0 ? (scale < 1 ? -1 : 1) : resolvedVelocity
        if let element = resolveElement(step, in: app) {
            if element.waitForExistence(timeout: elementTimeout) {
                performPinch(on: element, scale: scale, velocity: velocity)
            }
            return
        }
        performPinch(on: app, scale: scale, velocity: velocity)
    }

    /// Perform the pinch gesture in a way that compiles on every platform the test target builds for.
    ///
    /// On the iOS Simulator we use the native `XCUIElement.pinch(withScale:velocity:)` so the local
    /// `just ui-walkthrough` produces a genuine zoom-out gesture (AC6 evidence). That API is
    /// unavailable on Mac Catalyst (CI's "Build & Test" destination), so there we synthesise the same
    /// pinch from two simultaneous press-drag gestures between coordinates: the two fingers start near
    /// the element centre and move apart (zoom in, `scale > 1`) or together (zoom out, `scale < 1`).
    private func performPinch(on element: XCUIElement, scale: Double, velocity: Double) {
        #if targetEnvironment(macCatalyst)
            let center = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            // Zoom out: fingers start far apart and converge. Zoom in: start near and diverge.
            let startSpread: CGFloat = scale < 1 ? 0.25 : 0.05
            let endSpread: CGFloat = scale < 1 ? 0.05 : 0.25
            let fingerOne = (
                start: center.withOffset(CGVector(dx: -startSpread * 100, dy: 0)),
                end: center.withOffset(CGVector(dx: -endSpread * 100, dy: 0))
            )
            let fingerTwo = (
                start: center.withOffset(CGVector(dx: startSpread * 100, dy: 0)),
                end: center.withOffset(CGVector(dx: endSpread * 100, dy: 0))
            )
            fingerOne.start.press(
                forDuration: 0.05,
                thenDragTo: fingerOne.end,
                withVelocity: .default,
                thenHoldForDuration: 0
            )
            fingerTwo.start.press(
                forDuration: 0.05,
                thenDragTo: fingerTwo.end,
                withVelocity: .default,
                thenHoldForDuration: 0
            )
        #else
            element.pinch(withScale: CGFloat(scale), velocity: CGFloat(velocity))
        #endif
    }

    /// Sleep for the requested number of seconds.
    private func wait(_ step: UIActionStep) {
        let seconds = step.seconds ?? 0
        if seconds > 0 {
            Thread.sleep(forTimeInterval: seconds)
        }
    }

    /// Resolve a target element by accessibility label first, then identifier. Returns `nil` when
    /// the step specifies no target (e.g. `mapTap`, `wait`).
    private func resolveElement(_ step: UIActionStep, in app: XCUIApplication) -> XCUIElement? {
        if let label = step.label, !label.isEmpty {
            return app.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", label))
                .firstMatch
        }
        if let identifier = step.identifier, !identifier.isEmpty {
            return app.descendants(matching: .any)
                .matching(identifier: identifier)
                .firstMatch
        }
        return nil
    }
}
