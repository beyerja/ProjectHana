import SwiftUI

enum HomeQuizMode: Hashable {
    case mapQuiz
    case multipleChoice
    case typeCapital
    case nameCountry

    var supportsNew: Bool {
        switch self {
        case .mapQuiz, .multipleChoice: return true
        case .typeCapital, .nameCountry: return false
        }
    }

    var icon: String {
        switch self {
        case .mapQuiz: return "map.fill"
        case .multipleChoice: return "list.bullet.circle.fill"
        case .typeCapital: return "building.columns.fill"
        case .nameCountry: return "globe.europe.africa.fill"
        }
    }

    var color: Color {
        switch self {
        case .mapQuiz: return .blue
        case .multipleChoice: return .orange
        case .typeCapital: return .purple
        case .nameCountry: return .indigo
        }
    }

    var titleKey: String {
        switch self {
        case .mapQuiz: return "quiz.mode.map_tap.title"
        case .multipleChoice: return "quiz.mode.multiple_choice.title"
        case .typeCapital: return "quiz.mode.type_capital.title"
        case .nameCountry: return "quiz.mode.name_country.title"
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
