import Foundation
import XCTest
@testable import Hanahuac

/// Test support for exercising the *real shipped* On-Demand-Resource language packs.
///
/// Since story 006 the non-base languages (fr/de/ko/nah) ship as ODR asset packs (`lang-<code>`),
/// not in the main app bundle, so their `.lproj` UI strings and `<code>-geo.json` are absent from
/// `Bundle.main` until the pack is downloaded. The simulator unit-test host has no asset-pack server,
/// so `NSBundleResourceRequest.beginAccessingResources` cannot actually mount packs into `Bundle.main`
/// there. To still validate the shipped pack CONTENT, these helpers locate the built `.assetpack`
/// directories on disk (emitted next to the app bundle under `OnDemandResources/`) and load the
/// language's `.lproj` / geo JSON directly from there.
///
/// When the asset packs are not reachable (e.g. an install layout that does not keep them beside the
/// app bundle), the helpers return `nil`/`throw XCTSkip` so content tests skip rather than fail —
/// the no-download fallback behavior is covered separately by the offline-path tests.
enum ODRTestSupport {
    /// Locate the on-disk asset-pack directory for `tag` (e.g. `lang-ko`), searching the
    /// `OnDemandResources/` directory that the build emits beside the app bundle. Returns `nil` when
    /// it cannot be found in this environment.
    static func assetPackURL(forTag tag: String) -> URL? {
        // The app bundle's parent in the build-products layout contains `OnDemandResources/`.
        let candidates = [
            Bundle.main.bundleURL.deletingLastPathComponent(),
            Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        ]
        for base in candidates {
            let odr = base.appendingPathComponent("OnDemandResources", isDirectory: true)
            guard let entries = try? FileManager.default.contentsOfDirectory(
                at: odr,
                includingPropertiesForKeys: nil
            ) else {
                continue
            }
            // Asset-pack dirs are named `<bundleid>.<tag>-<hash>.assetpack`.
            if let match = entries.first(where: {
                $0.lastPathComponent.contains(".\(tag)-") && $0.pathExtension == "assetpack"
            }) {
                return match
            }
        }
        return nil
    }

    /// Load the `.lproj` `Bundle` shipped in `locale`'s ODR pack, reading it from the on-disk asset
    /// pack. Throws `XCTSkip` when the pack is not reachable in this environment.
    static func lprojBundle(for locale: AppLocale) throws -> Bundle {
        guard let tag = locale.odrTags.first else {
            throw XCTSkip("\(locale.rawValue) is a bundled base language with no ODR pack")
        }
        guard let pack = assetPackURL(forTag: tag) else {
            throw XCTSkip("ODR asset pack for \(tag) not reachable in this test environment")
        }
        let lproj = pack.appendingPathComponent("\(locale.rawValue).lproj", isDirectory: true)
        guard let bundle = Bundle(url: lproj) else {
            throw XCTSkip("ODR \(locale.rawValue).lproj not found in asset pack \(pack.lastPathComponent)")
        }
        return bundle
    }
}
