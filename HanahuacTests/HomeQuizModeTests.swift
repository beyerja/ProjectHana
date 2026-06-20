import XCTest
@testable import Hanahuac

/// Story 003: the home screen wiring and new+pending parity for the text modes.
final class HomeQuizModeTests: XCTestCase {
    // MARK: - "Name That Place" offered for every category

    func testNameFeatureOfferedForEveryCategory() {
        for category in [CardCategory.country, .river, .mountain, .sea] {
            XCTAssertTrue(
                HomeQuizMode.modes(for: category).contains(.nameFeature),
                "nameFeature should be offered for \(category)"
            )
        }
    }

    // MARK: - "Type the Capital" stays Countries-only

    func testTypeCapitalOnlyForCountries() {
        XCTAssertTrue(HomeQuizMode.modes(for: .country).contains(.typeCapital))
        for category in [CardCategory.river, .mountain, .sea] {
            XCTAssertFalse(
                HomeQuizMode.modes(for: category).contains(.typeCapital),
                "typeCapital should not be offered for \(category)"
            )
        }
    }

    // MARK: - New + pending parity

    func testTextModesSupportNewPile() {
        XCTAssertTrue(HomeQuizMode.nameFeature.supportsNew)
        XCTAssertTrue(HomeQuizMode.typeCapital.supportsNew)
    }

    func testEveryModeSupportsNewPile() {
        for mode in [HomeQuizMode.mapQuiz, .multipleChoice, .typeCapital, .nameFeature] {
            XCTAssertTrue(mode.supportsNew, "\(mode) should support the new pile")
        }
    }

    // MARK: - Title keys are wired (and the old name_country key is gone)

    func testNameFeatureTitleKey() {
        XCTAssertEqual(HomeQuizMode.nameFeature.titleKey, "quiz.mode.name_feature.title")
    }
}
