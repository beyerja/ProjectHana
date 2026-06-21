import Foundation

/// A typed error describing why a ``GeoNamePackData`` blob could not be turned into usable pack data.
///
/// Every failure here is recoverable: the caller catches it and falls back to bundled names. Unlike
/// `GeographyDataLoader.loadJSON`, the pack loader NEVER calls `fatalError` — a malformed or
/// untrusted pack (which, for ODR/CDN variants, may originate outside the app binary) must degrade
/// gracefully, never crash the app.
enum GeoNamePackError: Error, Equatable {
    /// The bytes were not valid JSON or did not match the ``GeoNamePackData`` shape.
    case malformedJSON
    /// The pack's `version` is not in ``GeoNamePackData/supportedVersions``.
    case unsupportedVersion(Int)
    /// The pack's `code` was empty.
    case emptyLanguageCode
    /// An entry was structurally invalid (e.g. both `name` and `capital` absent, or a blank id).
    case invalidEntry(id: String)
}

/// Decodes and schema-validates ``GeoNamePackData`` from raw JSON `Data`, regardless of where that
/// data came from (bundled resource, ODR, or a future signed CDN download).
enum GeoNamePackLoader {
    /// Decode and validate `data`, throwing a ``GeoNamePackError`` on any problem.
    ///
    /// Validation rules:
    /// - The JSON must decode into ``GeoNamePackData``.
    /// - `version` must be in ``GeoNamePackData/supportedVersions``.
    /// - `code` must be non-empty.
    /// - Every entry id must be non-empty and the entry must carry at least one of `name`/`capital`.
    static func decode(_ data: Data) throws -> GeoNamePackData {
        let pack: GeoNamePackData
        do {
            pack = try JSONDecoder().decode(GeoNamePackData.self, from: data)
        } catch {
            throw GeoNamePackError.malformedJSON
        }
        try validate(pack)
        return pack
    }

    /// Decode and validate `data`, returning `nil` on any failure instead of throwing. Convenience
    /// for call sites that want a pure "best effort, else bundled fallback" path with no error
    /// inspection.
    static func decodeOrNil(_ data: Data) -> GeoNamePackData? {
        try? decode(data)
    }

    /// Validate an already-decoded pack against the schema rules, throwing on the first violation.
    static func validate(_ pack: GeoNamePackData) throws {
        guard GeoNamePackData.supportedVersions.contains(pack.version) else {
            throw GeoNamePackError.unsupportedVersion(pack.version)
        }
        guard !pack.code.isEmpty else {
            throw GeoNamePackError.emptyLanguageCode
        }
        for (id, entry) in pack.entries {
            guard !id.isEmpty else {
                throw GeoNamePackError.invalidEntry(id: id)
            }
            let hasName = !(entry.name?.isEmpty ?? true)
            let hasCapital = !(entry.capital?.isEmpty ?? true)
            guard hasName || hasCapital else {
                throw GeoNamePackError.invalidEntry(id: id)
            }
        }
    }
}
