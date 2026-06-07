import Foundation

struct River: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let continent: String
    let sourceLat: Double
    let sourceLon: Double
    let mouthLat: Double
    let mouthLon: Double
}
