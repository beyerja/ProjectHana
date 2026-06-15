import Foundation

/// Resolves the set of `MappableFeature`s for a given quiz category, drawn from
/// the bundled geography data. Used by the map quiz / map learning views and
/// sessions so they are category-driven rather than `Country`-specific.
enum MapFeatureCatalog {
    /// All mappable features for `category`, sourced from `GeographyDataLoader`.
    static func features(for category: CardCategory) -> [any MappableFeature] {
        let data = GeographyDataLoader.shared
        switch category {
        case .country:  return data.countries
        // River / MountainRange / Sea conformance to MappableFeature is added in
        // stories 002–004; each returns its features once it conforms.
        case .river:    return data.rivers.map { $0 as any MappableFeature }
        case .mountain: return data.mountains.map { $0 as any MappableFeature }
        case .sea:      return data.seas.map { $0 as any MappableFeature }
        }
    }
}
