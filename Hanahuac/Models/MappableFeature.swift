import Foundation
import CoreLocation

/// A geography entity that can be presented on the map quiz / map learning map:
/// a tappable pin, an optional polygon border overlay, and optional line
/// endpoints (used by rivers, which are drawn as a line between two points).
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

    /// The two endpoints of a drawn line (source, mouth), or `nil` when the
    /// feature is not rendered as a line. Only rivers provide endpoints.
    var lineEndpoints: (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D)? { get }
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

    var lineEndpoints: (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D)? { nil }
}

// MARK: - River conformance (line + midpoint pin)

extension River: MappableFeature {
    /// Source and mouth endpoints of the drawn line.
    var lineEndpoints: (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D)? {
        (CLLocationCoordinate2D(latitude: sourceLat, longitude: sourceLon),
         CLLocationCoordinate2D(latitude: mouthLat, longitude: mouthLon))
    }

    /// Midpoint of the source→mouth line.
    var pinCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: (sourceLat + mouthLat) / 2,
                               longitude: (sourceLon + mouthLon) / 2)
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

    var lineEndpoints: (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D)? { nil }
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

    var lineEndpoints: (start: CLLocationCoordinate2D, end: CLLocationCoordinate2D)? { nil }
}
