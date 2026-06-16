import SwiftUI

enum HomeQuizMode: Hashable {
    case mapQuiz
    case multipleChoice
    case typeCapital
    case nameCountry

    var supportsNew: Bool {
        switch self {
        case .mapQuiz, .multipleChoice: true
        case .typeCapital, .nameCountry: false
        }
    }

    var icon: String {
        switch self {
        case .mapQuiz: "map.fill"
        case .multipleChoice: "list.bullet.circle.fill"
        case .typeCapital: "building.columns.fill"
        case .nameCountry: "globe.europe.africa.fill"
        }
    }

    var color: Color {
        switch self {
        case .mapQuiz: Theme.Palette.country
        case .multipleChoice: Theme.Palette.accentDeep
        case .typeCapital: Theme.Palette.mountain
        case .nameCountry: Theme.Palette.sea
        }
    }

    var titleKey: String {
        switch self {
        case .mapQuiz: "quiz.mode.map_tap.title"
        case .multipleChoice: "quiz.mode.multiple_choice.title"
        case .typeCapital: "quiz.mode.type_capital.title"
        case .nameCountry: "quiz.mode.name_country.title"
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
