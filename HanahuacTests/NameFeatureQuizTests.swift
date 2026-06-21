import SwiftData
import XCTest
@testable import Hanahuac

/// Tests for the map-pin "Name that feature" quiz session logic (story 001):
/// the `TextQuizSession.nameFeatureQuestions` factory + matching across categories
/// and locales, SM-2 scheduling on advance (pending pile), and graduation on the
/// learning path (new pile, reusing `LearningSession`).
@MainActor
final class NameFeatureQuizTests: XCTestCase {
    private var container: ModelContainer!
    private var savedProvider: LanguagePackProvider!

    override func setUpWithError() throws {
        let schema = Schema([ReviewCard.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])

        // Geo `localizedName` resolves through the active provider keyed by geo id, so activate a
        // bundled provider built from this test's own fixtures (otherwise the default provider, built
        // from the real shipped geography, would carry the real "de"/"rhine" names, not these).
        savedProvider = LanguagePackProviderHolder.active
        let geography = GeographyData(
            countries: [germany()],
            rivers: [rhine()],
            mountains: [],
            seas: []
        )
        LanguagePackProviderHolder.active = BundledLanguagePackProvider(geography: geography)
    }

    override func tearDown() {
        LanguagePackProviderHolder.active = savedProvider
        super.tearDown()
    }

    private func makeCard(factID: String, category: CardCategory = .country) -> ReviewCard {
        let card = ReviewCard(factID: factID, category: category)
        container.mainContext.insert(card)
        return card
    }

    // Germany: localized in fr/de/es, plus ko/nah.
    private func germany() -> Country {
        Country(
            id: "de",
            name: "Germany",
            nameFr: "Allemagne",
            nameDe: "Deutschland",
            nameEs: "Alemania",
            nameKo: "독일",
            nameNah: nil, // no Nahuatl → falls back es → en
            capital: "Berlin",
            capitalFr: "Berlin",
            capitalDe: "Berlin",
            capitalEs: "Berlín",
            continent: "Europe",
            lat: 51,
            lon: 10
        )
    }

    private func rhine() -> River {
        River(
            id: "rhine", name: "Rhine", nameFr: "Rhin", nameDe: "Rhein", nameEs: "Rin",
            continent: "Europe", sourceLat: 46.8, sourceLon: 9.2, mouthLat: 51.9, mouthLon: 4.0
        )
    }

    // MARK: - Factory pairs each card with its feature

    func testNameFeatureQuestions_pairsCardWithFeature_skipsUnknown() {
        let cards = [makeCard(factID: "de"), makeCard(factID: "unknown")]
        let qs = TextQuizSession.nameFeatureQuestions(
            cards: cards, features: [germany()], locale: .en
        )
        XCTAssertEqual(qs.count, 1)
        XCTAssertEqual(qs.first?.card.factID, "de")
        XCTAssertEqual(qs.first?.correctAnswer, "Germany")
    }

    // MARK: - Localized primary answer matches

    func testNameFeatureQuestions_germanLocale_acceptsGermanName() {
        let session = TextQuizSession(questions: TextQuizSession.nameFeatureQuestions(
            cards: [makeCard(factID: "de")], features: [germany()], locale: .de
        ))
        session.checkAnswer("deutschland") // case-insensitive
        XCTAssertEqual(session.answerState, .correct)
    }

    func testNameFeatureQuestions_koreanLocale_acceptsKoreanName() {
        let session = TextQuizSession(questions: TextQuizSession.nameFeatureQuestions(
            cards: [makeCard(factID: "de")], features: [germany()], locale: .ko
        ))
        session.checkAnswer("독일")
        XCTAssertEqual(session.answerState, .correct)
    }

    // MARK: - English fallback for non-English locales

    func testNameFeatureQuestions_germanLocale_acceptsEnglishFallback() {
        let session = TextQuizSession(questions: TextQuizSession.nameFeatureQuestions(
            cards: [makeCard(factID: "de")], features: [germany()], locale: .de
        ))
        session.checkAnswer("Germany") // English fallback accepted
        XCTAssertEqual(session.answerState, .correct)
    }

    /// Nahuatl with no nah name resolves to Spanish ("Alemania"); the English name is
    /// still accepted as a fallback.
    func testNameFeatureQuestions_nahuatlLocale_spanishPrimaryAndEnglishFallback() {
        let qs = TextQuizSession.nameFeatureQuestions(
            cards: [makeCard(factID: "de")], features: [germany()], locale: .nah
        )
        XCTAssertEqual(qs.first?.correctAnswer, "Alemania")
        let s1 = TextQuizSession(questions: qs)
        s1.checkAnswer("alemania")
        XCTAssertEqual(s1.answerState, .correct)
        let s2 = TextQuizSession(questions: qs)
        s2.checkAnswer("Germany")
        XCTAssertEqual(s2.answerState, .correct)
    }

    /// English locale: no fallback is set (and a wrong answer reveals the English name).
    func testNameFeatureQuestions_englishLocale_noFallback_wrongRevealsName() {
        let qs = TextQuizSession.nameFeatureQuestions(
            cards: [makeCard(factID: "de")], features: [germany()], locale: .en
        )
        XCTAssertNil(qs.first?.fallbackAnswer)
        let session = TextQuizSession(questions: qs)
        session.checkAnswer("France")
        guard case let .incorrect(answer) = session.answerState else {
            return XCTFail("expected incorrect")
        }
        XCTAssertEqual(answer, "Germany")
    }

    // MARK: - Works for a non-country category (river)

    func testNameFeatureQuestions_river_acceptsLocalizedName() {
        let session = TextQuizSession(questions: TextQuizSession.nameFeatureQuestions(
            cards: [makeCard(factID: "rhine", category: .river)], features: [rhine()], locale: .fr
        ))
        session.checkAnswer("Rhin")
        XCTAssertEqual(session.answerState, .correct)
    }

    // MARK: - Pending pile: SM-2 quality on advance

    func testAdvance_correctSchedulesQuality4_wrongQuality1() {
        // Correct answer → quality 4 → repetitionCount increments, card scheduled forward.
        let correctCard = makeCard(factID: "de")
        let sCorrect = TextQuizSession(questions: TextQuizSession.nameFeatureQuestions(
            cards: [correctCard], features: [germany()], locale: .en
        ))
        sCorrect.checkAnswer("Germany")
        sCorrect.advance()
        XCTAssertEqual(correctCard.lastQualityScore, 4)
        XCTAssertGreaterThan(correctCard.repetitionCount, 0)

        // Wrong answer → quality 1 → repetition resets to 0 (SM-2 lapse).
        let wrongCard = makeCard(factID: "de")
        let sWrong = TextQuizSession(questions: TextQuizSession.nameFeatureQuestions(
            cards: [wrongCard], features: [germany()], locale: .en
        ))
        sWrong.checkAnswer("Nope")
        sWrong.advance()
        XCTAssertEqual(wrongCard.lastQualityScore, 1)
    }

    // MARK: - New pile: graduation after 3 consecutive correct (reuses LearningSession)

    func testLearningSession_graduatesAfterThreeCorrect() {
        let card = makeCard(factID: "de")
        let session = LearningSession(newCards: [card])
        XCTAssertFalse(card.hasGraduated)
        session.recordCorrect()
        session.recordCorrect()
        session.recordCorrect()
        XCTAssertTrue(card.hasGraduated, "card should graduate after 3 consecutive correct")
        XCTAssertEqual(session.graduatedCount, 1)
    }

    func testLearningSession_wrongResetsStreak() {
        let card = makeCard(factID: "de")
        let session = LearningSession(newCards: [card])
        session.recordCorrect()
        session.recordWrong()
        XCTAssertEqual(card.consecutiveCorrect, 0)
        XCTAssertFalse(card.hasGraduated)
    }
}
