import Foundation

/// Bridges the geo models' raw per-language fields into ``GeoNamePackData`` for the bundled provider.
///
/// `rawName(for:)`/`rawCapital(for:)` return the *unresolved* value for exactly one language (no
/// fallback-chain walking — that is ``GeoNameResolver``'s job), or `nil` when this language has no
/// value. The bundled provider uses these to assemble a per-language pack from the bundled geo JSON;
/// the base (`en`) name is intentionally not a pack field (it is the resolver's final fallback).
extension Country {
    func rawName(for locale: AppLocale) -> String? {
        switch locale {
        case .fr: nameFr
        case .de: nameDe
        case .esMX: nameEs
        case .esES: nameEsEs
        case .ko: nameKo
        case .nah: nameNah
        case .en: nil
        }
    }

    func rawCapital(for locale: AppLocale) -> String? {
        switch locale {
        case .fr: capitalFr
        case .de: capitalDe
        case .esMX: capitalEs
        case .esES: capitalEsEs
        case .ko: capitalKo
        case .nah: capitalNah
        case .en: nil
        }
    }
}

extension River {
    func rawName(for locale: AppLocale) -> String? {
        switch locale {
        case .fr: nameFr
        case .de: nameDe
        case .esMX: nameEs
        case .esES: nameEsEs
        case .ko: nameKo
        case .nah: nameNah
        case .en: nil
        }
    }
}

extension MountainRange {
    func rawName(for locale: AppLocale) -> String? {
        switch locale {
        case .fr: nameFr
        case .de: nameDe
        case .esMX: nameEs
        case .esES: nameEsEs
        case .ko: nameKo
        case .nah: nameNah
        case .en: nil
        }
    }
}

extension Sea {
    func rawName(for locale: AppLocale) -> String? {
        switch locale {
        case .fr: nameFr
        case .de: nameDe
        case .esMX: nameEs
        case .esES: nameEsEs
        case .ko: nameKo
        case .nah: nameNah
        case .en: nil
        }
    }
}
