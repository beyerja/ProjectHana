import CoreLocation
import Foundation

/// Loads the bundled `river-paths.json` of real river-centerline geometry derived
/// from Natural Earth (`ne_10m_rivers_lake_centerlines`, see
/// `scripts/generate-river-paths.py`). Each entry maps a river `id` to one or more
/// ordered polyline parts (source→mouth where determinable); a genuinely
/// braided/disjoint river may carry multiple parts.
///
/// JSON schema (one object per line), either single- or multi-part:
///   {"id": "nile",   "path":  [[lon, lat], ...]}
///   {"id": "amazon", "parts": [[[lon, lat], ...], ...]}
///
/// Returns an empty dictionary when the resource is missing or fails to decode, so
/// any river without bundled geometry falls back to the straight source→mouth line
/// (mirroring the mountains pin-only graceful-degradation pattern).
enum RiverPathLoader {
    static let shared: [String: [[CLLocationCoordinate2D]]] = load(resource: "river-paths")

    static func load(resource: String) -> [String: [[CLLocationCoordinate2D]]] {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([RiverPathEntry].self, from: data) else {
            return [:]
        }
        var result: [String: [[CLLocationCoordinate2D]]] = [:]
        for entry in entries {
            let rawParts = entry.parts ?? entry.path.map { [$0] } ?? []
            let parts = rawParts
                .map { part in part.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) } }
                .filter { $0.count >= 2 }
            if !parts.isEmpty {
                result[entry.id] = parts
            }
        }
        return result
    }

    private struct RiverPathEntry: Decodable {
        let id: String
        let path: [[Double]]?
        let parts: [[[Double]]]?
    }
}
