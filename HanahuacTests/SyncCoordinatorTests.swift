import SwiftData
import XCTest
@testable import Hanahuac

@MainActor
final class SyncCoordinatorTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test.sync.\(UUID().uuidString)")!
    }

    // MARK: - Default (flag OFF) behavior

    func testDefaultIsLocalOnlyAndUnavailableWhenNotCompiledIn() {
        // In the default build CLOUDKIT_SYNC is not defined, so sync is never available regardless
        // of iCloud account state.
        let coordinator = SyncCoordinator(
            availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: true),
            preferenceDefaults: freshDefaults()
        )
        XCTAssertFalse(SyncFeatureFlag.isCompiledIn)
        XCTAssertFalse(coordinator.isSyncAvailable)
        XCTAssertFalse(coordinator.isSyncActive)
        XCTAssertEqual(coordinator.status, .unavailable)
    }

    func testDefaultSelectsLocalStores() {
        let coordinator = SyncCoordinator(
            availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: true),
            preferenceDefaults: freshDefaults()
        )
        XCTAssertTrue(coordinator.makeActiveSetStore() is UserDefaultsActiveSetStore)
        // Preference store is local-backed; round-trips through UserDefaults default suite.
        let prefs = coordinator.makePreferenceStore()
        prefs.setString("es-MX", forKey: .appLocale)
        XCTAssertEqual(prefs.string(forKey: .appLocale), "es-MX")
    }

    // MARK: - Opt-in persistence

    func testOptInPersistsAcrossInstances() {
        let defaults = freshDefaults()
        let first = SyncCoordinator(
            availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: false),
            preferenceDefaults: defaults
        )
        XCTAssertFalse(first.userOptedIn, "Opt-in defaults to OFF")
        first.setOptIn(true)

        let second = SyncCoordinator(
            availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: false),
            preferenceDefaults: defaults
        )
        XCTAssertTrue(second.userOptedIn, "Opt-in choice must persist")
    }

    // MARK: - Sign-out / unavailable fallback

    func testICloudUnavailableResolvesToUnavailableAndLocalFallback() {
        let coordinator = SyncCoordinator(
            availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: false),
            preferenceDefaults: freshDefaults()
        )
        coordinator.setOptIn(true) // user wants sync...
        // ...but no iCloud account → unavailable + local fallback, no crash.
        XCTAssertEqual(coordinator.status, .unavailable)
        XCTAssertFalse(coordinator.isSyncActive)
        XCTAssertTrue(coordinator.makeActiveSetStore() is UserDefaultsActiveSetStore)
    }

    // MARK: - Container factory

    func testMakeModelContainerProducesUsableLocalContainer() {
        let container = SyncCoordinator.makeModelContainer()
        let store = CardStore(modelContext: ModelContext(container))
        store.upsert(ReviewCard(factID: "smoke-test", category: .country))
        XCTAssertTrue(store.allCards.contains { $0.factID == "smoke-test" })
        store.resetAll()
    }

    // MARK: - Status transitions are observable

    func testStatusRecomputesOnOptInChange() {
        // Force availability true; in default build flag is off so it stays unavailable. We assert
        // refreshStatus is wired and idempotent.
        let coordinator = SyncCoordinator(
            availability: FixedICloudAvailabilityProvider(isICloudAccountAvailable: true),
            preferenceDefaults: freshDefaults()
        )
        let before = coordinator.status
        coordinator.setOptIn(true)
        let after = coordinator.refreshStatus()
        // Without CLOUDKIT_SYNC, both are .unavailable; the point is refreshStatus runs cleanly.
        XCTAssertEqual(before, .unavailable)
        XCTAssertEqual(after, .unavailable)
    }
}
