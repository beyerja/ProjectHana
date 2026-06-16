import MapKit
import SwiftUI

// MARK: - Pin view

/// The tappable map pin used by the map quiz and map learning views, for every
/// category (countries, rivers, mountains, seas).
struct MapFeaturePinView: View {
    enum State { case neutral, correct, incorrectTapped, correctRevealed }

    let state: State
    let name: String

    private var color: Color {
        switch state {
        case .neutral: Theme.Palette.accent
        case .correct: Theme.Palette.correct
        case .incorrectTapped: Theme.Palette.wrong
        case .correctRevealed: Theme.Palette.correct
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(radius: 2)
            if state == .correctRevealed || state == .correct {
                Text(name)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color, in: Capsule())
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

/// Backwards-compatible alias — the original country-only pin type.
typealias CountryPinView = MapFeaturePinView

// MARK: - Pin state

/// Maps the current `AnswerState` to the pin appearance for a given feature.
func mapPinState(featureID: String, answerState: AnswerState) -> MapFeaturePinView.State {
    switch answerState {
    case .unanswered:
        return .neutral
    case let .correct(id):
        return featureID == id ? .correct : .neutral
    case let .incorrect(tappedID, correctID):
        if featureID == tappedID { return .incorrectTapped }
        if featureID == correctID { return .correctRevealed }
        return .neutral
    }
}

// MARK: - Overlay content

/// Builds the polygon and polyline overlays for the annotation features in a map
/// quiz / learning session. Polygons come from `borderRings`; polylines from
/// `linePath` (rivers) — one `MapPolyline` per ordered part, so a river follows
/// its real multi-point course (and braided rivers draw multiple parts). A
/// two-point fallback part is densified so the straight line still reads smoothly.
@MainActor
@MapContentBuilder
func featureOverlays(
    for features: [any MappableFeature],
    answerState: AnswerState
) -> some MapContent {
    ForEach(features, id: \.id) { feature in
        if let rings = feature.borderRings {
            ForEach(rings.indices, id: \.self) { i in
                MapPolygon(coordinates: rings[i])
                    .foregroundStyle(answerState.polygonFillColor(for: feature.id))
                    .stroke(.white.opacity(0.55), lineWidth: 0.8)
            }
        }
        if let parts = feature.linePath {
            ForEach(parts.indices, id: \.self) { i in
                MapPolyline(coordinates: renderableCoordinates(parts[i]))
                    .stroke(lineStrokeColor(for: feature.id, answerState: answerState), lineWidth: 4)
            }
        }
    }
}

/// Colour for a river's drawn line given the answer state. Mirrors the polygon
/// highlight semantics but with full opacity so the line stays visible.
private func lineStrokeColor(for featureID: String, answerState: AnswerState) -> Color {
    switch answerState {
    case .unanswered:
        return Theme.Palette.accent.opacity(0.9)
    case let .correct(id):
        return featureID == id ? Theme.Palette.correct : Theme.Palette.accent.opacity(0.6)
    case let .incorrect(tappedID, correctID):
        if featureID == correctID { return Theme.Palette.correct }
        if featureID == tappedID { return Theme.Palette.wrong }
        return Theme.Palette.accent.opacity(0.6)
    }
}

/// Prepares a polyline part for rendering. A real multi-point centerline (>2
/// vertices) is already detailed, so it is drawn as-is. A two-point fallback part
/// (the straight source→mouth line) is densified into intermediate points so the
/// straight line still reads as a smooth stroke across the projection.
private func renderableCoordinates(_ part: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
    guard part.count == 2 else { return part }
    return greatCircleSegments(from: part[0], to: part[1])
}

/// Densifies a straight segment into intermediate points so MapKit renders a
/// smooth line across the projection.
private func greatCircleSegments(
    from start: CLLocationCoordinate2D,
    to end: CLLocationCoordinate2D,
    steps: Int = 24
) -> [CLLocationCoordinate2D] {
    guard steps > 1 else { return [start, end] }
    return (0 ... steps).map { i in
        let t = Double(i) / Double(steps)
        return CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * t,
            longitude: start.longitude + (end.longitude - start.longitude) * t
        )
    }
}
