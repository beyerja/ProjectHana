import Foundation

/// Pure mapping from `SyncStatus` to the localized-key + tint the Settings UI should show.
/// Kept free of SwiftUI so it can be unit-tested directly.
enum SyncStatusPresentation {
    /// Localization key for the status label.
    static func labelKey(for status: SyncStatus) -> String {
        switch status {
        case .off: return "settings.sync.status.off"
        case .unavailable: return "settings.sync.status.unavailable"
        case .on: return "settings.sync.status.on"
        case .syncing: return "settings.sync.status.syncing"
        case .idle: return "settings.sync.status.idle"
        case .error: return "settings.sync.status.error"
        }
    }

    /// Whether the opt-in toggle should be interactive. When sync is unavailable the toggle is
    /// disabled so it cannot appear to silently succeed.
    static func isToggleEnabled(for status: SyncStatus) -> Bool {
        status != .unavailable
    }

    /// Localization key for the explanatory footnote shown beneath the toggle when unavailable.
    static func footnoteKey(for status: SyncStatus) -> String? {
        status == .unavailable ? "settings.sync.unavailable_note" : nil
    }
}
