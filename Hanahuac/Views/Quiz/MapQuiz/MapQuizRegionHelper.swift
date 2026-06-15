import Foundation
import MapKit

/// Shared helper for building the map quiz annotation set and visible region.
///
/// - Returns a shuffled array of `neighbourCount` nearest neighbours plus the
///   correct feature, and an `MKCoordinateRegion` whose center is randomly
///   offset so the target feature can appear anywhere in the viewport (not
///   always at the center).
///
/// Generic over any `MappableFeature` so it serves countries, rivers, mountains,
/// and seas with one implementation.
func makeQuizAnnotations(
    correct: any MappableFeature,
    allFeatures: [any MappableFeature],
    neighbourCount: Int = 10
) -> (features: [any MappableFeature], region: MKCoordinateRegion) {
    let neighbours = allFeatures
        .filter { $0.id != correct.id }
        .sorted { quizDistance($0, from: correct) < quizDistance($1, from: correct) }
        .prefix(neighbourCount)

    let annotationFeatures = ([correct] + neighbours).shuffled()
    let region = quizRegion(for: annotationFeatures, correct: correct)
    return (annotationFeatures, region)
}

// MARK: - Private helpers

private func quizDistance(_ a: any MappableFeature, from b: any MappableFeature) -> Double {
    let dLat = a.quizLat - b.quizLat
    let dLon = a.quizLon - b.quizLon
    return sqrt(dLat * dLat + dLon * dLon)
}

private func quizRegion(for features: [any MappableFeature], correct: any MappableFeature) -> MKCoordinateRegion {
    guard !features.isEmpty else { return MKCoordinateRegion() }

    let lats = features.map(\.quizLat)
    let lons = features.map(\.quizLon)

    // Span large enough to fit all neighbours, with a 1.6x padding factor and 20° floor.
    let rawSpanLat = (lats.max()! - lats.min()!) * 1.6
    let rawSpanLon = (lons.max()! - lons.min()!) * 1.6
    let spanLat = max(20, rawSpanLat)
    let spanLon = max(20, rawSpanLon)

    // Offset the center randomly within ±30% of the span so the target feature
    // can appear near the center or near the edges.
    let maxOffsetFraction = 0.30
    let latOffset = Double.random(in: -spanLat * maxOffsetFraction ... spanLat * maxOffsetFraction)
    let lonOffset = Double.random(in: -spanLon * maxOffsetFraction ... spanLon * maxOffsetFraction)

    let centerLat = correct.quizLat + latOffset
    let centerLon = correct.quizLon + lonOffset

    return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
        span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
    )
}
