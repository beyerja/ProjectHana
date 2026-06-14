import SwiftUI

enum MasteryTier: String, CaseIterable {
    case new       = "New"
    case learning  = "Learning"
    case review    = "Review"
    case mastered  = "Mastered"

    static func classify(_ card: ReviewCard) -> MasteryTier {
        switch card.repetitionCount {
        case 0:
            return .new
        case 1, 2:
            return .learning
        case 3, 4:
            return .review
        default:
            return card.easeFactor >= 2.0 ? .mastered : .review
        }
    }

    var color: Color {
        switch self {
        case .new:      return .gray
        case .learning: return .yellow
        case .review:   return .blue
        case .mastered: return .green
        }
    }

    var icon: String {
        switch self {
        case .new:      return "circle"
        case .learning: return "flame"
        case .review:   return "arrow.clockwise"
        case .mastered: return "star.fill"
        }
    }
}
