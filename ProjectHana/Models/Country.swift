import Foundation

struct Country: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let capital: String
    let continent: String
    let lat: Double
    let lon: Double
}
