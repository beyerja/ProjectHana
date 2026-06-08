import Foundation
import CoreLocation

struct CountryBorderLoader {
    static let shared: [String: [[CLLocationCoordinate2D]]] = load()

    private static func load() -> [String: [[CLLocationCoordinate2D]]] {
        guard let url = Bundle.main.url(forResource: "country-borders", withExtension: "json") else {
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
