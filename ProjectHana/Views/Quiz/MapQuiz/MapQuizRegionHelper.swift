import Foundation
import MapKit

/// Shared helper for building the map quiz annotation set and visible region.
///
/// - Returns a shuffled array of `neighbourCount` neighbours plus the correct country,
///   and an `MKCoordinateRegion` whose center is randomly offset so the target country
///   can appear anywhere in the viewport (not always at the center).
func makeQuizAnnotations(
    correct: Country,
    allCountries: [Country],
    neighbourCount: Int = 10
) -> (countries: [Country], region: MKCoordinateRegion) {
    let neighbours = allCountries
        .filter { $0.id != correct.id }
        .sorted { quizDistance($0, from: correct) < quizDistance($1, from: correct) }
        .prefix(neighbourCount)

    let annotationCountries = ([correct] + neighbours).shuffled()
    let region = quizRegion(for: annotationCountries, correct: correct)
    return (annotationCountries, region)
}

// MARK: - Private helpers

private func quizDistance(_ a: Country, from b: Country) -> Double {
    let dLat = a.lat - b.lat
    let dLon = a.lon - b.lon
    return sqrt(dLat * dLat + dLon * dLon)
}

private func quizRegion(for countries: [Country], correct: Country) -> MKCoordinateRegion {
    guard !countries.isEmpty else { return MKCoordinateRegion() }

    let lats = countries.map(\.lat)
    let lons = countries.map(\.lon)

    // Span large enough to fit all neighbours, with a 1.6x padding factor and 20° floor.
    let rawSpanLat = (lats.max()! - lats.min()!) * 1.6
    let rawSpanLon = (lons.max()! - lons.min()!) * 1.6
    let spanLat = max(20, rawSpanLat)
    let spanLon = max(20, rawSpanLon)

    // Offset the center randomly within ±30% of the span so the target country
    // can appear near the center or near the edges.
    let maxOffsetFraction = 0.30
    let latOffset = Double.random(in: -spanLat * maxOffsetFraction ... spanLat * maxOffsetFraction)
    let lonOffset = Double.random(in: -spanLon * maxOffsetFraction ... spanLon * maxOffsetFraction)

    let centerLat = correct.lat + latOffset
    let centerLon = correct.lon + lonOffset

    return MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
        span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
    )
}
