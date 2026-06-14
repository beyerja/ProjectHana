import Foundation
import SwiftData
import Observation

/// Central seam that decides — based on the single `SyncFeatureFlag` plus iCloud availability and
/// the user's opt-in choice — whether the app runs in CloudKit-backed or local-only mode, and that
/// selects the matching `ModelContainer` configuration and key-value stores.
///
/// With the flag OFF (the default, and the only state buildable/CI-able under free signing) the
/// coordinator reproduces today's local-only behavior exactly: an on-disk SwiftData store and
/// `UserDefaults`-backed active-set/preferences. The CloudKit branch is written and compiles, but
/// is gated behind `#if CLOUDKIT_SYNC` and is never taken by default.
///
/// Conflict resolution intentionally relies on CloudKit's default last-writer-wins; no custom merge
/// logic lives here.
@Observable
final class SyncCoordinator {
    /// Persisted opt-in choice. The user can opt in even when sync is currently unavailable; the
    /// choice is remembered for when it becomes available.
    var userOptedIn: Bool {
        didSet { preferenceDefaults.set(userOptedIn, forKey: Self.optInKey) }
    }

    /// The current user-visible sync status, derived from flag + availability + opt-in.
    private(set) var status: SyncStatus

    @ObservationIgnored private let availability: ICloudAvailabilityProviding
    @ObservationIgnored private let preferenceDefaults: UserDefaults

    static let optInKey = "sync.userOptedIn"

    init(
        availability: ICloudAvailabilityProviding = SystemICloudAvailabilityProvider(),
        preferenceDefaults: UserDefaults = .standard
    ) {
        self.availability = availability
        self.preferenceDefaults = preferenceDefaults
        self.userOptedIn = preferenceDefaults.bool(forKey: Self.optInKey)
        self.status = SyncStatus.off  // placeholder; recomputed below
        self.status = computeStatus()
    }

    // MARK: - Eligibility & status

    /// Sync can actually run only when it is compiled in AND an iCloud account is available.
    var isSyncAvailable: Bool {
        SyncFeatureFlag.isCompiledIn && availability.isICloudAccountAvailable
    }

    /// Sync is active when available and the user has opted in.
    var isSyncActive: Bool {
        isSyncAvailable && userOptedIn
    }

    /// Recompute and publish status. Call after availability or opt-in changes.
    @discardableResult
    func refreshStatus() -> SyncStatus {
        status = computeStatus()
        return status
    }

    private func computeStatus() -> SyncStatus {
        guard isSyncAvailable else { return .unavailable }
        return userOptedIn ? .on : .off
    }

    func setOptIn(_ optedIn: Bool) {
        userOptedIn = optedIn
        refreshStatus()
    }

    // MARK: - Store selection (reuses Story 002 types)

    /// The active-set store to inject: ubiquitous when sync is active, local `UserDefaults` otherwise.
    func makeActiveSetStore() -> ActiveSetStore {
        isSyncActive ? makeUbiquitousActiveSetStore() : UserDefaultsActiveSetStore()
    }

    /// The preference store to inject: ubiquitous when sync is active, local otherwise.
    func makePreferenceStore() -> PreferenceStore {
        isSyncActive ? makeUbiquitousPreferenceStore() : makeLocalPreferenceStore()
    }

    // MARK: - ModelContainer factory

    /// Builds the app's `ModelContainer`.
    ///
    /// - flag OFF (default): a local on-disk configuration, identical to the original `HanahuacApp`
    ///   setup (no `cloudKitDatabase`).
    /// - flag ON: a configuration that attaches the private CloudKit database, compiled only behind
    ///   `#if CLOUDKIT_SYNC` so the default build never references the entitlement-bound API.
    ///
    /// On failure the on-disk store is wiped and recreated (data re-seeds from bundled JSON), so a
    /// schema change — or an iCloud sign-out that orphans a CloudKit-backed store — degrades to a
    /// fresh local store rather than crashing.
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([ReviewCard.self])
        let config = makeConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed without a migration plan (or store incompatible) — wipe and start fresh.
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
            }
            // Fall back to a guaranteed-local configuration so the app still launches.
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    private static func makeConfiguration(schema: Schema) -> ModelConfiguration {
        #if CLOUDKIT_SYNC
        // Only reached when the project is built with CLOUDKIT_SYNC + iCloud entitlements present.
        return ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(SyncFeatureFlag.containerIdentifier)
        )
        #else
        // Default: local-only, byte-compatible with the original HanahuacApp configuration.
        return ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        #endif
    }
}
