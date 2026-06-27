import SwiftUI

/// Maps the language-driven RTL signal (``AppLocale/isRTL``) onto SwiftUI's `LayoutDirection`, and
/// provides the single modifier that drives the whole app's layout direction from the selected
/// language. Keeping this in one place means stories 009/010 (ar/ur) are a VERIFICATION of working
/// infrastructure, not new wiring.
extension AppLocale {
    /// The SwiftUI layout direction for this language: `.rightToLeft` for the RTL languages (ar, ur),
    /// `.leftToRight` for every other language. Derived from ``isRTL`` so the RTL set stays centralized
    /// in the catalog.
    var layoutDirection: LayoutDirection {
        isRTL ? .rightToLeft : .leftToRight
    }
}

extension View {
    /// Drive this subtree's layout direction from the SELECTED language, so picking an RTL language
    /// (Arabic, Urdu) mirrors the entire app — independently of the device locale. Applied once at the
    /// app root; every descendant inherits the environment value and SwiftUI mirrors leading/trailing
    /// layout, navigation chrome, and direction-aware SF Symbols automatically.
    func appLayoutDirection(for locale: AppLocale) -> some View {
        environment(\.layoutDirection, locale.layoutDirection)
    }
}

/// Resolves a forced/overridden layout direction from the launch environment, so XCUITests and the UI
/// walkthrough driver can exercise the RTL layout BEFORE ar/ur content exists (and on an LTR host).
///
/// The override is intentionally launch-only and language-agnostic: it answers "force RTL?" without
/// requiring a specific RTL language to be selectable, which is exactly what story 008 needs to test
/// the infrastructure in isolation.
enum LayoutDirectionOverride {
    /// Launch-argument / environment key. When present and truthy the app forces `.rightToLeft`; when
    /// present and falsy it forces `.leftToRight`; when absent the language-driven direction wins.
    static let forceRTLKey = "HANA_FORCE_RTL"

    /// The forced direction from the environment, or `nil` when no override is set (language wins).
    static func forcedDirection(
        from environment: [String: String] = ProcessInfo.processInfo.environment,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> LayoutDirection? {
        // A bare `-HANA_FORCE_RTL` launch argument (no value) forces RTL — the simplest thing a UI
        // test can pass via `launchArguments`.
        if arguments.contains("-\(forceRTLKey)") || arguments.contains(forceRTLKey) {
            return .rightToLeft
        }
        guard let raw = environment[forceRTLKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }
        switch raw.lowercased() {
        case "1", "true", "yes", "rtl":
            return .rightToLeft
        case "0", "false", "no", "ltr":
            return .leftToRight
        default:
            return nil
        }
    }
}

extension View {
    /// Apply the language-driven layout direction, honoring a launch-time `HANA_FORCE_RTL` override
    /// when present. This is the single root-level seam: production reads the selected language; tests
    /// and the walkthrough force a direction without needing ar/ur content.
    func appLayoutDirection(for locale: AppLocale, override: LayoutDirection?) -> some View {
        environment(\.layoutDirection, override ?? locale.layoutDirection)
    }
}
