import Foundation
import CoreLocation

/// Loads a bundled `*-borders.json` file of the shape
/// `[{"id": "<id>", "rings": [[[lon, lat], ...], ...]}]` into a dictionary of
/// `id → polygon rings`. Shared by countries, seas, and mountains.
///
/// Returns an empty dictionary if the resource is missing or fails to decode, so
/// a category with no bundled border file simply renders pin-only.
enum BorderLoader {
    static func load(resource: String) -> [String: [[CLLocationCoordinate2D]]] {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            return [:]
        }
        guard let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([BorderEntry].self, from: data) else {
            return [:]
        }
        var result: [String: [[CLLocationCoordinate2D]]] = [:]
        for entry in entries {
            result[entry.id] = entry.rings.map { ring in
                ring.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
            }
        }
        return result
    }

    private struct BorderEntry: Decodable {
        let id: String
        let rings: [[[Double]]]
    }
}

/// Marine polygon rings keyed by sea id, loaded from `sea-borders.json`.
enum SeaBorderLoader {
    static let shared: [String: [[CLLocationCoordinate2D]]] = BorderLoader.load(resource: "sea-borders")
}

/// Mountain-range polygon rings keyed by range id, loaded from
/// `mountain-borders.json`. Ranges absent from the file render pin-only.
enum MountainBorderLoader {
    static let shared: [String: [[CLLocationCoordinate2D]]] = BorderLoader.load(resource: "mountain-borders")
}
