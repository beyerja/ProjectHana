import Foundation
import CoreLocation

/// A geography entity that can be presented on the map quiz / map learning map:
/// a tappable pin, an optional polygon border overlay, and an optional multi-point
/// line path (used by rivers, which are drawn along their real course).
///
/// `Country`, `River`, `MountainRange`, and `Sea` all conform. The map quiz UI,
/// the map sessions, and the annotation/region helper are written against this
/// protocol so they work for every category without category-specific code.
protocol MappableFeature {
    /// Stable identifier, matching the entity's `id` and the card `factID`.
    var id: String { get }

    /// Localized display name for the current app locale.
    func localizedName(for locale: AppLocale) -> String

    /// The tappable pin coordinate.
    ///
    /// - Countries: pole of inaccessibility of the mainland border ring.
    /// - Seas / mountains: the explicit lat/lon from their bundled JSON.
    /// - Rivers: the midpoint of the source→mouth line.
    var pinCoordinate: CLLocationCoordinate2D { get }

    /// Polygon border rings to overlay, or `nil` when the feature has no polygon
    /// (rivers, or seas/mountains with no confidently matched border).
    var borderRings: [[CLLocationCoordinate2D]]? { get }

    /// The drawn line as one or more ordered polyline parts, or `nil` when the
    /// feature is not rendered as a line. Only rivers provide a path: the real
    /// multi-point centerline when matched, otherwise a single straight
    /// source→mouth part as a graceful fallback. Multiple parts support genuinely
    /// braided/disjoint rivers.
    var linePath: [[CLLocationCoordinate2D]]? { get }
}

extension MappableFeature {
    /// Latitude of the pin — used by the region helper for neighbour selection.
    var quizLat: Double { pinCoordinate.latitude }
    /// Longitude of the pin — used by the region helper for neighbour selection.
    var quizLon: Double { pinCoordinate.longitude }
}

// MARK: - Country conformance

extension Country: MappableFeature {
    var pinCoordinate: CLLocationCoordinate2D {
        CountryPinCoordinateProvider.shared.coordinate(for: self)
    }

    var borderRings: [[CLLocationCoordinate2D]]? {
        CountryBorderLoader.shared[id]
    }

    var linePath: [[CLLocationCoordinate2D]]? { nil }
}

// MARK: - River conformance (real path or straight fallback + midpoint pin)

extension River: MappableFeature {
    /// The straight source→mouth line as a single part — the graceful fallback
    /// used when no real centerline geometry is bundled for this river.
    var straightLinePart: [CLLocationCoordinate2D] {
        [CLLocationCoordinate2D(latitude: sourceLat, longitude: sourceLon),
         CLLocationCoordinate2D(latitude: mouthLat, longitude: mouthLon)]
    }

    /// Real multi-point centerline parts from `river-paths.json` when matched,
    /// otherwise the single straight source→mouth part.
    var linePath: [[CLLocationCoordinate2D]]? {
        RiverPathLoader.shared[id] ?? [straightLinePart]
    }

    /// The tappable pin. For a matched river it sits on the real path — the path
    /// vertex nearest the path's halfway point by cumulative length — so the pin
    /// lands ON the river. With no bundled geometry it falls back to the
    /// source→mouth midpoint (unchanged behaviour).
    var pinCoordinate: CLLocationCoordinate2D {
        if let vertex = RiverPathLoader.shared[id].flatMap(River.midpointVertex(of:)) {
            return vertex
        }
        return CLLocationCoordinate2D(latitude: (sourceLat + mouthLat) / 2,
                                      longitude: (sourceLon + mouthLon) / 2)
    }

    /// Returns the vertex closest to the halfway point (by cumulative length)
    /// across all parts of a river path, or `nil` for an empty/degenerate path.
    static func midpointVertex(of parts: [[CLLocationCoordinate2D]]) -> CLLocationCoordinate2D? {
        let vertices = parts.flatMap { $0 }
        guard vertices.count > 1 else { return vertices.first }
        func seg(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
            let dLat = a.latitude - b.latitude, dLon = a.longitude - b.longitude
            return (dLat * dLat + dLon * dLon).squareRoot()
        }
        // Cumulative length to each vertex (parts concatenated in order).
        var cumulative = [0.0]
        for i in 1..<vertices.count {
            cumulative.append(cumulative[i - 1] + seg(vertices[i - 1], vertices[i]))
        }
        let half = (cumulative.last ?? 0) / 2
        var best = 0, bestDelta = Double.greatestFiniteMagnitude
        for (i, c) in cumulative.enumerated() where abs(c - half) < bestDelta {
            bestDelta = abs(c - half); best = i
        }
        return vertices[best]
    }

    var borderRings: [[CLLocationCoordinate2D]]? { nil }
}

// MARK: - Sea conformance (polygon overlay + pin)

extension Sea: MappableFeature {
    var pinCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Marine border rings from `sea-borders.json`, or `nil` (pin-only) when no
    /// polygon is matched for this sea.
    var borderRings: [[CLLocationCoordinate2D]]? {
        SeaBorderLoader.shared[id]
    }

    var linePath: [[CLLocationCoordinate2D]]? { nil }
}

// MARK: - MountainRange conformance (polygon overlay + pin, with fallback)

extension MountainRange: MappableFeature {
    var pinCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Range border rings from `mountain-borders.json`, or `nil` (pin-only) when
    /// no polygon is confidently matched for this range.
    var borderRings: [[CLLocationCoordinate2D]]? {
        MountainBorderLoader.shared[id]
    }

    var linePath: [[CLLocationCoordinate2D]]? { nil }
}
