import Foundation
import XCTest

/// Captures a per-step artifact pair under `.workflow/ui-walkthrough/<run>/`:
///   - `NNN-step.png`  — a full-screen `XCUIScreenshot` of the app
///   - `NNN-step.json` — a recursive accessibility-element dump (type/label/identifier/value/frame)
///
/// The UI-test process runs inside the simulator sandbox, so the repo's `.workflow/` directory is
/// resolved via the `HANA_REPO_ROOT` env var (passed through from the launching environment). When
/// that is absent the recorder falls back to the test bundle's temporary directory so the driver
/// never fails for want of a writable location.
struct UIWalkthroughRecorder {
    /// Env var giving the absolute path of the repo checkout (so artifacts land in the real tree).
    static let repoRootEnvKey = "HANA_REPO_ROOT"
    /// Env var overriding the `<run>` directory name (otherwise a UTC timestamp is used).
    static let runNameEnvKey = "HANA_UI_RUN"

    /// Directory all artifacts for this run are written to (created on init).
    let runDirectory: URL

    /// Build a recorder, resolving and creating the run directory.
    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        let root = Self.resolveRepoRoot(from: environment)
        let runName = Self.resolveRunName(from: environment)
        runDirectory = root
            .appendingPathComponent(".workflow", isDirectory: true)
            .appendingPathComponent("ui-walkthrough", isDirectory: true)
            .appendingPathComponent(runName, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: runDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Record both artifacts for a step.
    /// - Parameters:
    ///   - index: zero-based step index; the filename prefix is the 3-digit zero-padded value.
    ///   - app: the application to dump the element tree from.
    ///   - screenshot: the screenshot to persist (the caller captures it so timing is explicit).
    func record(index: Int, app: XCUIApplication, screenshot: XCUIScreenshot) {
        let prefix = String(format: "%03d", index)
        writeScreenshot(screenshot, prefix: prefix)
        writeElementDump(app: app, prefix: prefix)
    }

    /// Persist the screenshot PNG as `NNN-step.png`.
    private func writeScreenshot(_ screenshot: XCUIScreenshot, prefix: String) {
        let url = runDirectory.appendingPathComponent("\(prefix)-step.png")
        try? screenshot.pngRepresentation.write(to: url)
    }

    /// Persist the accessibility-element dump as `NNN-step.json`.
    private func writeElementDump(app: XCUIApplication, prefix: String) {
        let url = runDirectory.appendingPathComponent("\(prefix)-step.json")
        let elements = Self.dumpElements(of: app)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(elements) else {
            return
        }
        try? data.write(to: url)
    }

    /// Resolve the repo root from the environment, falling back to the temp dir when unset.
    private static func resolveRepoRoot(from environment: [String: String]) -> URL {
        if let raw = environment[repoRootEnvKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return URL(fileURLWithPath: raw, isDirectory: true)
        }
        return FileManager.default.temporaryDirectory
    }

    /// Resolve the run directory name from the env override or a UTC timestamp.
    private static func resolveRunName(from environment: [String: String]) -> String {
        if let raw = environment[runNameEnvKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return raw
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    /// Recursively snapshot every element of the app into encodable records.
    private static func dumpElements(of app: XCUIApplication) -> [UIElementRecord] {
        guard let snapshot = try? app.snapshot() else {
            return []
        }
        var records: [UIElementRecord] = []
        flatten(snapshot, into: &records)
        return records
    }

    /// Depth-first flatten of an element snapshot tree into a flat record list.
    private static func flatten(
        _ snapshot: XCUIElementSnapshot,
        into records: inout [UIElementRecord]
    ) {
        records.append(UIElementRecord(snapshot: snapshot))
        for child in snapshot.children {
            flatten(child, into: &records)
        }
    }
}

/// A single accessibility element captured for the per-step JSON dump.
struct UIElementRecord: Encodable {
    let type: String
    let label: String
    let identifier: String
    let value: String
    let frame: FrameRecord

    /// The element's frame as a plain encodable rectangle.
    struct FrameRecord: Encodable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }

    /// Build a record from an XCUITest element snapshot.
    init(snapshot: XCUIElementSnapshot) {
        type = String(describing: snapshot.elementType)
        label = snapshot.label
        identifier = snapshot.identifier
        value = (snapshot.value as? String) ?? ""
        let rect = snapshot.frame
        frame = FrameRecord(
            x: Double(rect.origin.x),
            y: Double(rect.origin.y),
            width: Double(rect.size.width),
            height: Double(rect.size.height)
        )
    }
}
