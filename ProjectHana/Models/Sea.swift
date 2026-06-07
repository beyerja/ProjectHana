import Foundation

struct Sea: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let lat: Double
    let lon: Double
}
