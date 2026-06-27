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
        case .ca: nameCa
        case .eu: nameEu
        case .yua: nameYua
        case .it: nameIt
        case .pl: namePl
        case .nl: nameNl
        case .sr: nameSr
        case .ko: nameKo
        case .nah: nameNah
        case .ja: nameJa
        case .zhHans: nameZhHans
        case .hi: nameHi
        case .bn: nameBn
        // Content-pending languages (story 002): the bundled geo source has no name column for these
        // yet, so they have no raw value until their content story (007-010) adds the column.
        case .en, .ar, .ptBR, .ur: nil
        }
    }

    func rawCapital(for locale: AppLocale) -> String? {
        switch locale {
        case .fr: capitalFr
        case .de: capitalDe
        case .esMX: capitalEs
        case .esES: capitalEsEs
        case .ca: capitalCa
        case .eu: capitalEu
        case .yua: capitalYua
        case .it: capitalIt
        case .pl: capitalPl
        case .nl: capitalNl
        case .sr: capitalSr
        case .ko: capitalKo
        case .nah: capitalNah
        case .ja: capitalJa
        case .zhHans: capitalZhHans
        case .hi: capitalHi
        case .bn: capitalBn
        // Content-pending languages (story 002): the bundled geo source has no capital column for
        // these yet, so they have no raw value until their content story (007-010) adds the column.
        case .en, .ar, .ptBR, .ur: nil
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
        case .ca: nameCa
        case .eu: nameEu
        case .yua: nameYua
        case .it: nameIt
        case .pl: namePl
        case .nl: nameNl
        case .sr: nameSr
        case .ko: nameKo
        case .nah: nameNah
        case .ja: nameJa
        case .zhHans: nameZhHans
        case .hi: nameHi
        case .bn: nameBn
        // Content-pending languages (story 002): the bundled geo source has no name column for these
        // yet, so they have no raw value until their content story (007-010) adds the column.
        case .en, .ar, .ptBR, .ur: nil
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
        case .ca: nameCa
        case .eu: nameEu
        case .yua: nameYua
        case .it: nameIt
        case .pl: namePl
        case .nl: nameNl
        case .sr: nameSr
        case .ko: nameKo
        case .nah: nameNah
        case .ja: nameJa
        case .zhHans: nameZhHans
        case .hi: nameHi
        case .bn: nameBn
        // Content-pending languages (story 002): the bundled geo source has no name column for these
        // yet, so they have no raw value until their content story (007-010) adds the column.
        case .en, .ar, .ptBR, .ur: nil
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
        case .ca: nameCa
        case .eu: nameEu
        case .yua: nameYua
        case .it: nameIt
        case .pl: namePl
        case .nl: nameNl
        case .sr: nameSr
        case .ko: nameKo
        case .nah: nameNah
        case .ja: nameJa
        case .zhHans: nameZhHans
        case .hi: nameHi
        case .bn: nameBn
        // Content-pending languages (story 002): the bundled geo source has no name column for these
        // yet, so they have no raw value until their content story (007-010) adds the column.
        case .en, .ar, .ptBR, .ur: nil
        }
    }
}
