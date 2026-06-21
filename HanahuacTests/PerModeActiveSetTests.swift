import XCTest
@testable import Hanahuac

/// Story 004 — the active set is namespaced per `(language, mode, category)`, so advancing one mode's
/// active set for a `(language, category)` leaves the other modes' active sets untouched, and the
/// pre-per-mode per-language key is still reachable as the Story-005 migration source.
final class PerModeActiveSetTests: XCTestCase {
    private let lang = AppLocale.en.rawValue
    private let suiteName = "PerModeActiveSetTests"
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
    }

    func testKeyIsNamespacedByMode() {
        XCTAssertEqual(
            activeSetKey(language: "en", mode: .mapQuiz, category: .country),
            "activeSet.en.mapQuiz.country"
        )
        XCTAssertEqual(
            activeSetKey(language: "en", mode: .multipleChoice, category: .country),
            "activeSet.en.multipleChoice.country"
        )
    }

    func testNilModeIsTheLegacyPerLanguageKey() {
        XCTAssertEqual(activeSetKey(language: "en", category: .country), "activeSet.en.country")
        XCTAssertEqual(
            legacyPerLanguageActiveSetKey(language: "en", category: .country),
            "activeSet.en.country"
        )
    }

    func testAdvancingOneModeLeavesOtherModesUntouched() {
        let map = UserDefaultsActiveSetStore(language: lang, mode: .mapQuiz, defaults: defaults)
        let mc = UserDefaultsActiveSetStore(language: lang, mode: .multipleChoice, defaults: defaults)

        map.save(["us", "fr"], for: .country)
        XCTAssertEqual(map.load(for: .country), ["us", "fr"])
        XCTAssertTrue(mc.load(for: .country).isEmpty, "multipleChoice active set is independent of mapQuiz")

        mc.save(["de"], for: .country)
        XCTAssertEqual(map.load(for: .country), ["us", "fr"], "mapQuiz active set is unaffected by multipleChoice")
        XCTAssertEqual(mc.load(for: .country), ["de"])
    }

    func testClearOneModeDoesNotClearAnother() {
        let map = UserDefaultsActiveSetStore(language: lang, mode: .mapQuiz, defaults: defaults)
        let mc = UserDefaultsActiveSetStore(language: lang, mode: .multipleChoice, defaults: defaults)
        map.save(["us"], for: .country)
        mc.save(["de"], for: .country)
        map.clear(for: .country)
        XCTAssertTrue(map.load(for: .country).isEmpty)
        XCTAssertEqual(mc.load(for: .country), ["de"], "Clearing mapQuiz must not touch multipleChoice")
    }

    func testLegacyPerLanguageStoreIsReachableAsMigrationSource() {
        // A pre-per-mode store (mode: nil) writes/reads the legacy per-language key — the Story-005
        // migration copies from here into the mapQuiz per-mode key.
        let legacy = UserDefaultsActiveSetStore(language: lang, mode: nil, defaults: defaults)
        legacy.save(["us", "fr"], for: .country)
        XCTAssertEqual(
            defaults.stringArray(forKey: legacyPerLanguageActiveSetKey(language: lang, category: .country)),
            ["us", "fr"]
        )
        // The mapQuiz per-mode store does NOT see the legacy data until migration copies it.
        let map = UserDefaultsActiveSetStore(language: lang, mode: .mapQuiz, defaults: defaults)
        XCTAssertTrue(map.load(for: .country).isEmpty)
    }
}
