import SwiftUI

enum HomeQuizMode: Hashable {
    case mapQuiz
    case multipleChoice
    case typeCapital
    /// Map-pin "Name That Place": the feature is pinned on the map and the user
    /// types its name. Offered for every category (replaces the old capital-based
    /// "Name the Country" mode).
    case nameFeature

    /// All quiz modes, in display order. (`HomeQuizMode` carries no associated values, so this is the
    /// stable full set the per-mode breakdown iterates over; the store layer iterates `QuizModeID`.)
    static let allModes: [HomeQuizMode] = [.mapQuiz, .multipleChoice, .typeCapital, .nameFeature]

    /// The stable persisted token (`QuizModeID`) this UI mode maps to. Progress is keyed by this raw
    /// value, so the model/store/migrator layers (which have no SwiftUI dependency) share one constant
    /// set with the views via this bridge.
    var quizModeID: QuizModeID {
        switch self {
        case .mapQuiz: .mapQuiz
        case .multipleChoice: .multipleChoice
        case .typeCapital: .typeCapital
        case .nameFeature: .nameFeature
        }
    }

    /// The persisted `quizMode` raw value for this UI mode — convenience for stores/sessions that
    /// stamp or scope by mode.
    var quizModeRawValue: String {
        quizModeID.rawValue
    }

    /// Reconstructs the UI mode from a persisted `QuizModeID` (e.g. when presenting a per-mode
    /// breakdown row from stored data).
    init(quizModeID: QuizModeID) {
        switch quizModeID {
        case .mapQuiz: self = .mapQuiz
        case .multipleChoice: self = .multipleChoice
        case .typeCapital: self = .typeCapital
        case .nameFeature: self = .nameFeature
        }
    }

    /// Every mode now participates in both the *new* and *pending* piles.
    var supportsNew: Bool {
        switch self {
        case .mapQuiz, .multipleChoice, .typeCapital, .nameFeature: true
        }
    }

    var icon: String {
        switch self {
        case .mapQuiz: "map.fill"
        case .multipleChoice: "list.bullet.circle.fill"
        case .typeCapital: "building.columns.fill"
        case .nameFeature: "mappin.and.ellipse"
        }
    }

    var color: Color {
        switch self {
        case .mapQuiz: Theme.Palette.country
        case .multipleChoice: Theme.Palette.accentDeep
        case .typeCapital: Theme.Palette.mountain
        case .nameFeature: Theme.Palette.sea
        }
    }

    var titleKey: String {
        switch self {
        case .mapQuiz: "quiz.mode.map_tap.title"
        case .multipleChoice: "quiz.mode.multiple_choice.title"
        case .typeCapital: "quiz.mode.type_capital.title"
        case .nameFeature: "quiz.mode.name_feature.title"
        }
    }

    /// The quiz modes offered for a given category on the home screen. The map-pin
    /// "Name That Place" mode is offered for every category; "Type the Capital" is
    /// Countries-only (only countries have capitals).
    static func modes(for category: CardCategory) -> [HomeQuizMode] {
        switch category {
        case .country: [.mapQuiz, .multipleChoice, .typeCapital, .nameFeature]
        case .river, .mountain, .sea: [.mapQuiz, .multipleChoice, .nameFeature]
        }
    }
}

enum Pile: Hashable {
    case new
    case pending
}

enum QuizRoute: Hashable {
    case pilePicker(mode: HomeQuizMode, category: CardCategory)
    case quiz(mode: HomeQuizMode, category: CardCategory, pile: Pile)
}
