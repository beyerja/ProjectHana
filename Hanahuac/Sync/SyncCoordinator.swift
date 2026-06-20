import Foundation
import Observation
import SwiftData

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
        userOptedIn = preferenceDefaults.bool(forKey: Self.optInKey)
        status = SyncStatus.off // placeholder; recomputed below
        status = computeStatus()
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
    /// The store is opened through a versioned schema + `HanahuacMigrationPlan`, so an
    /// additive/lightweight schema change in a new build migrates the existing store **in place**
    /// (progress preserved) instead of failing.
    ///
    /// If the container still cannot be opened, the recovery path is **non-destructive**: the
    /// existing store is first copied to a timestamped backup under
    /// `~/Library/Application Support/Hanahuac-backups/` (see ``ProgressBackup``), and only as a
    /// genuine last resort — when even a guaranteed-local container cannot open — is the store
    /// deleted. The backup is always the recovery point; the store is never wiped silently.
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = makeConfiguration(schema: schema)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: HanahuacMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            return recoverContainer(schema: schema, primaryError: error)
        }
    }

    /// Non-destructive recovery when the primary `ModelContainer` open fails.
    ///
    /// Order of operations (data safety first):
    /// 1. Back up the existing store to a timestamped `…-autorecover` directory (best-effort).
    /// 2. Try a guaranteed-local container WITHOUT deleting anything — a store that opens here keeps
    ///    all the user's progress.
    /// 3. Only if that also fails, delete the store (the backup from step 1 is the recovery point)
    ///    and try once more so the app can still launch.
    private static func recoverContainer(schema: Schema, primaryError: Error) -> ModelContainer {
        let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Step 1: back up before touching anything.
        let backupDir = ProgressBackup.backUpStore(at: storeURL, reason: "autorecover")

        // Step 2: try local WITHOUT wiping — preserves progress if the store is openable locally.
        if let container = try? ModelContainer(for: schema, configurations: [localConfig]) {
            return container
        }

        // Step 3: last resort — store is genuinely unopenable. The backup (step 1) is the recovery
        // point. Delete and recreate so the app still launches (data re-seeds from bundled JSON).
        for suffix in ProgressBackup.storeSuffixes {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            let backupNote = backupDir.map { " (a backup was saved to \($0.path))" } ?? ""
            fatalError(
                "Failed to create ModelContainer after non-destructive recovery"
                    + "\(backupNote). primary=\(primaryError) final=\(error)"
            )
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
