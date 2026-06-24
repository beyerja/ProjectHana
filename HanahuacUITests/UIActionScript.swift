import Foundation

/// The supported set of UI driver actions. The driver test is generic and data-driven: a JSON
/// script (a sequence of these steps) is loaded from the environment and executed in order against
/// the launched app. Targeting is by accessibility LABEL first (falling back to `identifier` when
/// provided) so the driver works before story 002 adds explicit accessibility identifiers.
enum UIActionKind: String, Codable {
    case tap
    case typeText
    case mapTap
    case swipe
    case scroll
    case wait
    case dumpTree
    case screenshot
}

/// A swipe/scroll direction.
enum UISwipeDirection: String, Codable {
    case up
    case down
    case left
    case right
}

/// A single decoded action-script step. All targeting/parameter fields are optional so the one
/// `Codable` model can represent every action kind; the driver reads only the fields relevant to
/// the step's `action`.
struct UIActionStep: Codable {
    /// Which action to perform.
    let action: UIActionKind
    /// Accessibility label of the target element (preferred matcher).
    let label: String?
    /// Accessibility identifier of the target element (used when present).
    let identifier: String?
    /// Text to type for `typeText`.
    let text: String?
    /// Normalized (0...1) x coordinate for `mapTap`.
    let x: Double?
    /// Normalized (0...1) y coordinate for `mapTap`.
    let y: Double?
    /// Direction for `swipe`/`scroll`.
    let direction: UISwipeDirection?
    /// Seconds to wait for `wait`.
    let seconds: Double?
}

/// Loads the action script from the environment, returning an EMPTY step list when no script is
/// configured or the configured payload is blank/empty. Never throws to the driver test body: a
/// missing or malformed script degrades to "no steps" so the driver still launches the app and
/// emits the initial artifacts.
enum UIActionScriptLoader {
    /// Environment variable holding a filesystem path to a JSON script.
    static let scriptPathEnvKey = "HANA_UI_SCRIPT_PATH"
    /// Environment variable holding inline JSON.
    static let inlineScriptEnvKey = "HANA_UI_SCRIPT"

    /// Resolve the action steps from the process environment.
    /// - Prefers `HANA_UI_SCRIPT_PATH` (a file path); falls back to `HANA_UI_SCRIPT` (inline JSON).
    /// - Returns `[]` when neither is set, the value is blank, the file is missing, or decoding
    ///   fails — the driver treats an empty list as "just emit the initial dump".
    static func load(from environment: [String: String] = ProcessInfo.processInfo.environment)
        -> [UIActionStep] {
        guard let data = rawJSONData(from: environment) else {
            return []
        }
        if data.isEmpty {
            return []
        }
        let decoder = JSONDecoder()
        guard let steps = try? decoder.decode([UIActionStep].self, from: data) else {
            return []
        }
        return steps
    }

    /// Resolve the raw JSON bytes from the environment, or `nil` when nothing usable is configured.
    private static func rawJSONData(from environment: [String: String]) -> Data? {
        if let path = trimmedValue(environment[scriptPathEnvKey]) {
            guard let contents = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                return nil
            }
            return blankToNil(contents)
        }
        if let inline = trimmedValue(environment[inlineScriptEnvKey]) {
            return Data(inline.utf8)
        }
        return nil
    }

    /// Trim a candidate env value, returning `nil` when it is missing or whitespace-only.
    private static func trimmedValue(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Reduce whitespace-only file contents to an empty `Data` so the loader treats them as "no steps".
    private static func blankToNil(_ data: Data) -> Data {
        guard let text = String(data: data, encoding: .utf8) else {
            return data
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Data() : data
    }
}
