import Foundation

struct MountainRange: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let continent: String
    let lat: Double
    let lon: Double
    let highestPeak: String
    let elevationMetres: Int
}
