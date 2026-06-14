import Foundation

struct MountainRange: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let continent: String
    let lat: Double
    let lon: Double
    let highestPeak: String
    let elevationMetres: Int

    func localizedName(for locale: AppLocale) -> String {
        switch locale {
        case .fr:   return nameFr ?? name
        case .de:   return nameDe ?? name
        case .esMX: return nameEs ?? name
        case .en:   return name
        }
    }
}
