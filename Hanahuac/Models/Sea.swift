import Foundation

struct Sea: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameFr: String?
    let nameDe: String?
    let nameEs: String?
    let lat: Double
    let lon: Double

    func localizedName(for locale: AppLocale) -> String {
        switch locale {
        case .fr: nameFr ?? name
        case .de: nameDe ?? name
        case .esMX: nameEs ?? name
        case .en: name
        }
    }
}
