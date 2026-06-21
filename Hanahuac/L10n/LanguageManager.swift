import Foundation
import Observation

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    /// Backing store for the synced preference. Defaults to the local (`UserDefaults`) store so
    /// behavior is identical to before. `SyncCoordinator` can hand in a sync-capable store.
    @ObservationIgnored private let preferences: PreferenceStore

    /// The currently selected locale. Setting this value persists it through `preferences` and, when
    /// the active provider delivers packs on demand, lazily triggers the download for the newly
    /// selected language. The trigger is the single selection-path hook: it is a no-op for the bundled
    /// provider and for base/already-downloaded languages, and adds no delivery-specific branching at
    /// any resolver call site. Resolution degrades to the fallback chain until the pack arrives.
    var current: AppLocale {
        didSet {
            preferences.setString(current.rawValue, forKey: .appLocale)
            let selected = current
            Task { @MainActor in
                LanguagePackProviderHolder.requestDownloadIfNeeded(for: selected)
            }
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
