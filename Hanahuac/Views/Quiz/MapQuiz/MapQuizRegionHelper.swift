import Foundation
import MapKit
import SwiftUI

/// Shared helper for building the map quiz annotation set and visible region.
///
/// - Returns a shuffled array of `neighbourCount` nearest neighbours plus the
///   correct feature, and an `MKCoordinateRegion` that is guaranteed to contain
///   **every** annotation pin (with margin and overlay insets) while still being
///   randomly jittered so the layout varies between questions.
///
/// Generic over any `MappableFeature` so it serves countries, rivers, mountains,
/// and seas with one implementation. This single implementation backs every map
/// quiz surface (`MapQuizView` via `MapQuizSession` and `MapLearningQuizView` via
/// `MapLearningSession`).
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
    let coords = annotationFeatures.map { ($0.quizLat, $0.quizLon) }
    let region = QuizRegionMath.region(fittingPins: coords, jitter: .random)
    return (annotationFeatures, region)
}

// MARK: - Private helpers

private func quizDistance(_ a: any MappableFeature, from b: any MappableFeature) -> Double {
    let dLat = a.quizLat - b.quizLat
    let dLon = a.quizLon - b.quizLon
    return sqrt(dLat * dLat + dLon * dLon)
}

/// Pure, testable region math for the map quiz.
///
/// All geometry is computed here so it can be unit-tested without MapKit view
/// state. The contract: the returned region's visible rect (after accounting for
/// the assumed portrait map aspect ratio and the top/bottom banner insets) always
/// contains every pin, for any allowed jitter draw.
enum QuizRegionMath {
    /// Fractional margin added around the outermost pins so they don't sit on the
    /// very edge of the screen.
    static let marginFraction = 0.18

    /// Assumed portrait map aspect ratio (width / height). The map quiz fills a
    /// portrait phone screen; using a conservative (narrow) width:height means we
    /// reserve enough longitudinal span that wide spreads never clip horizontally.
    /// ~0.46 ≈ a 9:19.5 phone with banners — deliberately conservative.
    static let mapAspectWidthOverHeight = 0.46

    /// Fraction of the total latitude span reserved, top + bottom, for the prompt
    /// banner and feedback banner overlays so pins are never hidden beneath them.
    static let verticalInsetFraction = 0.30

    /// Minimum span (degrees) applied when pins are coincident or nearly so, so a
    /// single-pin question still produces a sensible, readable zoom.
    static let minSpanDegrees = 12.0

    /// Largest allowed jitter as a fraction of the *slack* between the fitted span
    /// and the pin bounding box. Kept below 1.0 so a pin can never reach the edge.
    static let maxJitterFraction = 0.85

    enum Jitter {
        case none
        case random
        /// Deterministic fractional offset in [-1, 1] per axis (for tests).
        case fixed(latFraction: Double, lonFraction: Double)
    }

    /// Build a region centered on the bounding-box center of `pins`, sized to fit
    /// them all (plus margin, aspect correction, latitude correction, and banner
    /// insets), then jittered within a clamped range that keeps every pin visible.
    ///
    /// - Parameter pins: (latitude, longitude) pairs in degrees.
    static func region(
        fittingPins pins: [(Double, Double)],
        jitter: Jitter = .none
    ) -> MKCoordinateRegion {
        guard !pins.isEmpty else { return MKCoordinateRegion() }

        let lats = pins.map(\.0)
        let lons = pins.map(\.1)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        // Geographic extent of the pins.
        let pinLatExtent = maxLat - minLat
        let pinLonExtent = maxLon - minLon

        // Latitude compression: a degree of longitude spans less ground as |lat|
        // grows. To map the pins' geographic longitude extent onto screen width
        // correctly we must compare it against latitude in *screen-equivalent*
        // units, i.e. scale the longitude extent by cos(centerLat).
        let cosLat = max(0.2, cos(centerLat * .pi / 180))
        let lonExtentScreenEquivalent = pinLonExtent * cosLat

        // Required visible (screen) extents after adding margin around the pins.
        // Latitude additionally reserves room for the top/bottom banner overlays.
        let visibleLatExtent = max(
            pinLatExtent * (1 + marginFraction) / (1 - verticalInsetFraction),
            minSpanDegrees
        )
        let visibleLonScreenExtent = max(
            lonExtentScreenEquivalent * (1 + marginFraction),
            minSpanDegrees * mapAspectWidthOverHeight
        )

        // Aspect correction: the visible screen is portrait (height > width). The
        // ratio of on-screen width:height degrees must be at least the map's
        // aspect; otherwise a wide spread clips horizontally. Grow whichever axis
        // is too small while keeping the other.
        var spanLatScreen = visibleLatExtent
        var spanLonScreen = visibleLonScreenExtent
        let targetWidthOverHeight = mapAspectWidthOverHeight
        if spanLonScreen / spanLatScreen < targetWidthOverHeight {
            // Too narrow horizontally for the pins → grow longitude.
            spanLonScreen = spanLatScreen * targetWidthOverHeight
        } else {
            // Plenty of width → grow latitude to match the aspect so we don't
            // over-zoom vertically and clip top/bottom.
            spanLatScreen = spanLonScreen / targetWidthOverHeight
        }

        // Convert the screen-equivalent longitude span back to real degrees.
        let spanLat = spanLatScreen
        let spanLon = spanLonScreen / cosLat

        // Clamp jitter: the slack is how far the center can move on each axis while
        // still keeping the pin bounding box (with margin/inset) inside the span.
        // Vertical slack must also respect the banner inset region.
        let usableLatHalf = spanLat * (1 - verticalInsetFraction) / 2
        let latSlack = max(0, usableLatHalf - pinLatExtent / 2)
        let lonSlack = max(0, spanLon / 2 - pinLonExtent / 2)

        let (latFrac, lonFrac): (Double, Double)
        switch jitter {
        case .none:
            (latFrac, lonFrac) = (0, 0)
        case .random:
            (latFrac, lonFrac) = (
                Double.random(in: -1 ... 1),
                Double.random(in: -1 ... 1)
            )
        case let .fixed(lat, lon):
            (latFrac, lonFrac) = (max(-1, min(1, lat)), max(-1, min(1, lon)))
        }

        let jitteredLat = centerLat + latFrac * latSlack * maxJitterFraction
        let jitteredLon = centerLon + lonFrac * lonSlack * maxJitterFraction

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: jitteredLat, longitude: jitteredLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }

    /// Approximate metres per degree of latitude (constant; longitude is scaled by
    /// cos(latitude) in `cameraDistance(for:)`).
    static let metersPerDegreeLatitude = 111_320.0

    /// Headroom multiplier applied to the region span when deriving the camera's
    /// `maximumDistance`. Slightly above the fitted span so the framed region is
    /// honoured exactly while still hard-capping how far the camera may zoom out —
    /// far below the extent of the full-course river / large sea-mountain overlays.
    static let cameraDistanceHeadroom = 1.15

    /// The camera distance (in metres, the units of `MapCameraBounds`/`MapCamera`)
    /// that frames `region`'s span. Used to cap the map camera so it cannot zoom out
    /// to encompass overlay geometry (full river courses, large sea/mountain border
    /// polygons) that extends far beyond the candidate-pin bounding box.
    ///
    /// Derived from the larger on-screen (latitude-compression corrected) extent so
    /// neither axis clips, then converted from degrees to metres.
    static func cameraDistance(for region: MKCoordinateRegion) -> Double {
        let cosLat = max(0.2, cos(region.center.latitude * .pi / 180))
        let latExtentMeters = region.span.latitudeDelta * metersPerDegreeLatitude
        let lonExtentMeters = region.span.longitudeDelta * cosLat * metersPerDegreeLatitude
        return max(latExtentMeters, lonExtentMeters)
    }

    /// Camera bounds that pin the map to the candidate-pin `region` so overlay
    /// geometry (full-course river `linePath`, large sea/mountain `borderRings`)
    /// cannot re-frame the camera away from the pins. Constrains the camera centre to
    /// the region and caps the zoom-out distance to the region's framed span — the
    /// single shared mechanism used by both `MapQuizView` and `MapLearningQuizView`
    /// for every category. Framing stays derived purely from the bounding box of all
    /// candidate pins, independent of which pin is the answer (no hint leak).
    static func cameraBounds(for region: MKCoordinateRegion) -> MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: region,
            maximumDistance: cameraDistance(for: region) * cameraDistanceHeadroom
        )
    }

    /// Min/max lat & lon of the region area actually free of banner overlays — the
    /// area where a pin is genuinely visible to the user.
    struct VisibleRect {
        let minLat: Double
        let maxLat: Double
        let minLon: Double
        let maxLon: Double
    }

    /// The banner-free visible rect for a region. Used by tests to assert
    /// containment.
    static func visibleContentRect(for region: MKCoordinateRegion) -> VisibleRect {
        let usableLatHalf = region.span.latitudeDelta * (1 - verticalInsetFraction) / 2
        let lonHalf = region.span.longitudeDelta / 2
        return VisibleRect(
            minLat: region.center.latitude - usableLatHalf,
            maxLat: region.center.latitude + usableLatHalf,
            minLon: region.center.longitude - lonHalf,
            maxLon: region.center.longitude + lonHalf
        )
    }
}
