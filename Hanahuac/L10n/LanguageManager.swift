import Foundation
import Observation

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    /// Backing store for the synced preference. Defaults to the local (`UserDefaults`) store so
    /// behavior is identical to before. `SyncCoordinator` can hand in a sync-capable store.
    @ObservationIgnored private let preferences: PreferenceStore

    /// The currently selected locale. Setting this value persists it through `preferences`.
    var current: AppLocale {
        didSet {
            preferences.setString(current.rawValue, forKey: .appLocale)
        }
    }

    /// - Parameter preferences: where the selection is persisted. Defaults to the local store,
    ///   preserving the historical `UserDefaults`-backed behavior and key.
    init(preferences: PreferenceStore = makeLocalPreferenceStore()) {
        self.preferences = preferences
        // Restore a previously persisted selection, or resolve from the device locale.
        if let stored = preferences.string(forKey: .appLocale),
           let restored = AppLocale(rawValue: stored) {
            current = restored
        } else {
            current = AppLocale.matching(Locale.current)
        }
    }
}
