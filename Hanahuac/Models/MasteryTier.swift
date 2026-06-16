import SwiftUI

enum MasteryTier: String, CaseIterable {
    case new = "New"
    case learning = "Learning"
    case review = "Review"
    case mastered = "Mastered"

    static func classify(_ card: ReviewCard) -> MasteryTier {
        switch card.repetitionCount {
        case 0:
            .new
        case 1, 2:
            .learning
        case 3, 4:
            .review
        default:
            card.easeFactor >= 2.0 ? .mastered : .review
        }
    }

    var color: Color {
        switch self {
        case .new: .gray
        case .learning: .yellow
        case .review: .blue
        case .mastered: .green
        }
    }

    var icon: String {
        switch self {
        case .new: "circle"
        case .learning: "flame"
        case .review: "arrow.clockwise"
        case .mastered: "star.fill"
        }
    }
}
