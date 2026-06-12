import XCTest
import SwiftData
@testable import ProjectHana

/// Tests that MCQ factory methods produce correctly localized prompts and options.
@MainActor
final class LocalizedQuizPromptTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - countryCapitalQuestions: prompt contains localized country name

    func testCountryCapitalQuestions_frenchLocale_promptContainsFrenchName() {
        let card = makeCard(factID: "de")
        let countries = sampleCountries()
        let questions = MultipleChoiceSession.countryCapitalQuestions(
            cards: [card], countries: countries, locale: .fr
        )
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        XCTAssertTrue(q.prompt.contains("Allemagne"),
                      "French prompt should contain 'Allemagne', got: \(q.prompt)")
        XCTAssertFalse(q.prompt.contains("Germany"),
                       "French prompt must not contain English name 'Germany'")
    }

    func testCountryCapitalQuestions_germanLocale_promptContainsGermanName() {
        let card = makeCard(factID: "de")
        let countries = sampleCountries()
        let questions = MultipleChoiceSession.countryCapitalQuestions(
            cards: [card], countries: countries, locale: .de
        )
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        XCTAssertTrue(q.prompt.contains("Deutschland"),
                      "German prompt should contain 'Deutschland', got: \(q.prompt)")
        XCTAssertFalse(q.prompt.contains("Germany"),
                       "German prompt must not contain English name 'Germany'")
    }

    func testCountryCapitalQuestions_spanishLocale_promptContainsSpanishName() {
        let card = makeCard(factID: "de")
        let countries = sampleCountries()
        let questions = MultipleChoiceSession.countryCapitalQuestions(
            cards: [card], countries: countries, locale: .esMX
        )
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        XCTAssertTrue(q.prompt.contains("Alemania"),
                      "Spanish prompt should contain 'Alemania', got: \(q.prompt)")
        XCTAssertFalse(q.prompt.contains("Germany"),
                       "Spanish prompt must not contain English name 'Germany'")
    }

    /// Regression guard: English locale must produce same output as pre-feature behavior.
    func testCountryCapitalQuestions_englishLocale_promptContainsEnglishName() {
        let card = makeCard(factID: "de")
        let countries = sampleCountries()
        let questionsEn = MultipleChoiceSession.countryCapitalQuestions(
            cards: [card], countries: countries, locale: .en
        )
        let questionsDefault = MultipleChoiceSession.countryCapitalQuestions(
            cards: [card], countries: countries
        )
        guard let qEn = questionsEn.first, let qDefault = questionsDefault.first else {
            XCTFail("No questions generated"); return
        }
        XCTAssertTrue(qEn.prompt.contains("Germany"),
                      "English prompt should contain 'Germany', got: \(qEn.prompt)")
        XCTAssertEqual(qEn.prompt, qDefault.prompt,
                       "locale:.en should produce same prompt as default (no locale param)")
    }

    // MARK: - countryCapitalQuestions: options are localized

    func testCountryCapitalQuestions_frenchLocale_correctOptionIsFrenchCapital() {
        let card = makeCard(factID: "de")
        let countries = sampleCountries()
        let questions = MultipleChoiceSession.countryCapitalQuestions(
            cards: [card], countries: countries, locale: .fr
        )
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        let correct = q.options.first(where: \.isCorrect)
        XCTAssertEqual(correct?.label, "Berlin",
                       "French locale: correct option should be 'Berlin' (capital unchanged in French)")
    }

    // MARK: - continentQuestions: options are localized continent labels

    func testContinentQuestions_spanishLocale_correctOptionIsSpanishContinent() {
        let card = makeCard(factID: "rhine", category: .river)
        let questions = MultipleChoiceSession.continentQuestions(
            cards: [card],
            facts: sampleRivers(),
            factID: \.id,
            factName: \.name,
            factContinent: \.continent,
            categoryLabel: "river",
            locale: .esMX,
            factLocalizedName: { river, locale in river.localizedName(for: locale) }
        )
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        let correct = q.options.first(where: \.isCorrect)
        // "Europe" in Spanish (Mexican) should be "Europa"
        XCTAssertEqual(correct?.label, "Europa",
                       "Spanish locale: Europe continent label should be 'Europa', got: \(correct?.label ?? "nil")")
        // All options should be Spanish labels (none should be bare "Europe")
        for option in q.options {
            XCTAssertFalse(option.label == "Europe",
                           "No option should be the bare English 'Europe' when locale is esMX")
        }
    }

    func testContinentQuestions_frenchLocale_correctOptionIsFrenchContinent() {
        let card = makeCard(factID: "rhine", category: .river)
        let questions = MultipleChoiceSession.continentQuestions(
            cards: [card],
            facts: sampleRivers(),
            factID: \.id,
            factName: \.name,
            factContinent: \.continent,
            categoryLabel: "river",
            locale: .fr,
            factLocalizedName: { river, locale in river.localizedName(for: locale) }
        )
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        let correct = q.options.first(where: \.isCorrect)
        XCTAssertEqual(correct?.label, "Europe",
                       "French locale: Europe should be 'Europe' in French, got: \(correct?.label ?? "nil")")
    }

    func testContinentQuestions_germanLocale_correctOptionIsGermanContinent() {
        let card = makeCard(factID: "rhine", category: .river)
        let questions = MultipleChoiceSession.continentQuestions(
            cards: [card],
            facts: sampleRivers(),
            factID: \.id,
            factName: \.name,
            factContinent: \.continent,
            categoryLabel: "river",
            locale: .de,
            factLocalizedName: { river, locale in river.localizedName(for: locale) }
        )
        guard let q = questions.first else { XCTFail("No questions generated"); return }
        let correct = q.options.first(where: \.isCorrect)
        XCTAssertEqual(correct?.label, "Europa",
                       "German locale: Europe should be 'Europa' in German, got: \(correct?.label ?? "nil")")
    }

    /// Regression guard: English locale produces same continent label as before the feature.
    func testContinentQuestions_englishLocale_correctOptionIsEnglishContinent() {
        let card = makeCard(factID: "rhine", category: .river)
        let questionsEn = MultipleChoiceSession.continentQuestions(
            cards: [card],
            facts: sampleRivers(),
            factID: \.id,
            factName: \.name,
            factContinent: \.continent,
            categoryLabel: "river",
            locale: .en
        )
        let questionsDefault = MultipleChoiceSession.continentQuestions(
            cards: [card],
            facts: sampleRivers(),
            factID: \.id,
            factName: \.name,
            factContinent: \.continent,
            categoryLabel: "river"
        )
        guard let qEn = questionsEn.first, let qDefault = questionsDefault.first else {
            XCTFail("No questions generated"); return
        }
        let correctEn = qEn.options.first(where: \.isCorrect)
        let correctDefault = qDefault.options.first(where: \.isCorrect)
        XCTAssertEqual(correctEn?.label, "Europe")
        XCTAssertEqual(correctEn?.label, correctDefault?.label,
                       "locale:.en should produce same continent label as default (no locale param)")
    }

    // MARK: - Fixtures

    private func makeCard(factID: String, category: CardCategory = .country) -> ReviewCard {
        let card = ReviewCard(factID: factID, category: category)
        container.mainContext.insert(card)
        return card
    }

    private func sampleCountries() -> [Country] {
        [
            Country(id: "de", name: "Germany",
                    nameFr: "Allemagne", nameDe: "Deutschland", nameEs: "Alemania",
                    capital: "Berlin", capitalFr: "Berlin", capitalDe: "Berlin", capitalEs: "Berlín",
                    continent: "Europe", lat: 51, lon: 10),
            Country(id: "fr", name: "France",
                    nameFr: "France", nameDe: "Frankreich", nameEs: "Francia",
                    capital: "Paris", capitalFr: "Paris", capitalDe: "Paris", capitalEs: "París",
                    continent: "Europe", lat: 46, lon: 2),
            Country(id: "es", name: "Spain",
                    nameFr: "Espagne", nameDe: "Spanien", nameEs: "España",
                    capital: "Madrid", capitalFr: "Madrid", capitalDe: "Madrid", capitalEs: "Madrid",
                    continent: "Europe", lat: 40, lon: -4),
            Country(id: "it", name: "Italy",
                    nameFr: "Italie", nameDe: "Italien", nameEs: "Italia",
                    capital: "Rome", capitalFr: "Rome", capitalDe: "Rom", capitalEs: "Roma",
                    continent: "Europe", lat: 42, lon: 12),
            Country(id: "pt", name: "Portugal",
                    nameFr: "Portugal", nameDe: "Portugal", nameEs: "Portugal",
                    capital: "Lisbon", capitalFr: "Lisbonne", capitalDe: "Lissabon", capitalEs: "Lisboa",
                    continent: "Europe", lat: 39, lon: -8),
        ]
    }

    private func sampleRivers() -> [River] {
        [River(id: "rhine", name: "Rhine",
               nameFr: "Rhin", nameDe: "Rhein", nameEs: "Rin",
               continent: "Europe",
               sourceLat: 46.8, sourceLon: 9.2,
               mouthLat: 51.9, mouthLon: 4.0)]
    }
}
