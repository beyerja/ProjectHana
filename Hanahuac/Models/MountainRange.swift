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
        case .fr: nameFr ?? name
        case .de: nameDe ?? name
        case .esMX: nameEs ?? name
        case .en: name
        }
    }
}
