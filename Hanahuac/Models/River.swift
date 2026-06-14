import Foundation

struct River: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let continent: String
    let sourceLat: Double
    let sourceLon: Double
    let mouthLat: Double
    let mouthLon: Double

    func localizedName(for locale: AppLocale) -> String {
        switch locale {
        case .fr:   return nameFr ?? name
        case .de:   return nameDe ?? name
        case .esMX: return nameEs ?? name
        case .en:   return name
        }
    }
}
