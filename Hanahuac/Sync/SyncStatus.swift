import Foundation

/// User-visible sync state. `off` / `unavailable` / `on` are the states reachable today;
/// `syncing` / `idle` / `error` are forward-compatible for when live CloudKit sync is enabled.
enum SyncStatus: Equatable {
    /// Sync is compiled in and available, but the user has not opted in.
    case off
    /// Sync cannot run: not compiled in (no entitlement) or no iCloud account signed in.
    case unavailable
    /// Sync is enabled and available (the resting "on" state).
    case on
    /// Reserved for live sync: actively pushing/pulling.
    case syncing
    /// Reserved for live sync: enabled, available, nothing pending.
    case idle
    /// Reserved for live sync: an error occurred during sync.
    case error(String)
}

/// Abstracts "is an iCloud account available on this device?" so the coordinator can be unit-tested
/// without a live account. The live implementation reads `FileManager.ubiquityIdentityToken`, which
/// changes/zeroes on sign-out or Apple-ID change.
protocol ICloudAvailabilityProviding {
    var isICloudAccountAvailable: Bool { get }
}

/// Live availability via `FileManager.ubiquityIdentityToken`. Without the iCloud entitlement this
/// returns nil (token absent), which correctly resolves to `unavailable`.
struct SystemICloudAvailabilityProvider: ICloudAvailabilityProviding {
    var isICloudAccountAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}

/// Test/faked availability.
struct FixedICloudAvailabilityProvider: ICloudAvailabilityProviding {
    let isICloudAccountAvailable: Bool
}
