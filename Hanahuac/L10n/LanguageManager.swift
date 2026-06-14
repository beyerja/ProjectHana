import Foundation
import Observation

private let userDefaultsKey = "appLocale"

@Observable final class LanguageManager {
    static let shared = LanguageManager()

    /// The currently selected locale. Setting this value persists it to `UserDefaults`.
    var current: AppLocale {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: userDefaultsKey)
        }
    }

    private init() {
        // Restore a previously persisted selection, or resolve from the device locale.
        if let stored = UserDefaults.standard.string(forKey: userDefaultsKey),
           let restored = AppLocale(rawValue: stored) {
            current = restored
        } else {
            current = AppLocale.matching(Locale.current)
        }
    }
}
