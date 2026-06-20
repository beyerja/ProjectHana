import SwiftUI

enum HomeQuizMode: Hashable {
    case mapQuiz
    case multipleChoice
    case typeCapital
    /// Map-pin "Name That Place": the feature is pinned on the map and the user
    /// types its name. Offered for every category (replaces the old capital-based
    /// "Name the Country" mode).
    case nameFeature

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
