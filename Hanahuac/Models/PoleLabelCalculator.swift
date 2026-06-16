import CoreLocation

/// Computes the **pole of inaccessibility** for a polygon ring — the interior point
/// that is furthest from every edge. This guarantees the returned point is inside the
/// polygon and is visually well-centred even for concave or fjord-heavy coastlines.
///
/// The algorithm samples a uniform grid over the polygon's bounding box, tests each cell
/// centre for containment (ray-casting), then returns the interior candidate with the
/// largest minimum distance to any polygon edge.
///
/// Grid size: 40×40 cells is sufficient for all country polygons in this app (max ~370
/// vertices for Russia) and runs in well under 1 ms per polygon.
enum PoleLabelCalculator {
    // MARK: - Public API

    /// Returns the pole of inaccessibility for `ring`, or `nil` if the ring has fewer
    /// than 3 vertices or no interior point is found at the chosen grid resolution.
    static func compute(ring: [CLLocationCoordinate2D], gridSize: Int = 40) -> CLLocationCoordinate2D? {
        guard ring.count >= 3 else { return nil }

        let lons = ring.map(\.longitude)
        let lats = ring.map(\.latitude)
        guard let minLon = lons.min(), let maxLon = lons.max(),
              let minLat = lats.min(), let maxLat = lats.max() else { return nil }

        let lonSpan = maxLon - minLon
        let latSpan = maxLat - minLat
        guard lonSpan > 0, latSpan > 0 else { return nil }

        var bestDistanceSq: Double = -1
        var bestCoord: CLLocationCoordinate2D?

        for i in 0 ..< gridSize {
            for j in 0 ..< gridSize {
                let lon = minLon + lonSpan * (Double(i) + 0.5) / Double(gridSize)
                let lat = minLat + latSpan * (Double(j) + 0.5) / Double(gridSize)

                guard pointInPolygon(lon: lon, lat: lat, ring: ring) else { continue }

                let d = minDistanceToEdgeSquared(lon: lon, lat: lat, ring: ring)
                if d > bestDistanceSq {
                    bestDistanceSq = d
                    bestCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            }
        }

        return bestCoord
    }

    // MARK: - Private helpers

    /// Ray-casting point-in-polygon test. Returns true when (lon, lat) is strictly inside `ring`.
    static func pointInPolygon(lon: Double, lat: Double, ring: [CLLocationCoordinate2D]) -> Bool {
        let n = ring.count
        var inside = false
        var j = n - 1
        for i in 0 ..< n {
            let xi = ring[i].longitude, yi = ring[i].latitude
            let xj = ring[j].longitude, yj = ring[j].latitude
            if (yi > lat) != (yj > lat),
               lon < (xj - xi) * (lat - yi) / (yj - yi) + xi {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    /// Squared minimum distance from (lon, lat) to the nearest edge of `ring`.
    private static func minDistanceToEdgeSquared(
        lon: Double, lat: Double, ring: [CLLocationCoordinate2D]
    ) -> Double {
        var minDist = Double.infinity
        let n = ring.count
        for i in 0 ..< n {
            let ax = ring[i].longitude, ay = ring[i].latitude
            let bx = ring[(i + 1) % n].longitude, by = ring[(i + 1) % n].latitude
            let dx = bx - ax, dy = by - ay
            let distSq: Double
            if dx == 0, dy == 0 {
                let ex = lon - ax, ey = lat - ay
                distSq = ex * ex + ey * ey
            } else {
                let t = max(0, min(1, ((lon - ax) * dx + (lat - ay) * dy) / (dx * dx + dy * dy)))
                let px = ax + t * dx, py = ay + t * dy
                let ex = lon - px, ey = lat - py
                distSq = ex * ex + ey * ey
            }
            if distSq < minDist { minDist = distSq }
        }
        return minDist
    }
}
