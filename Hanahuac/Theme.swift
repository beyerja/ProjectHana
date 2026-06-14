import SwiftUI

/// Hanahuac's central design system — a warm pastel palette (light mode only).
///
/// Colors are defined once here so the whole app stays consistent and the scheme is easy to
/// retune. The palette nods to Hanahuac's roots: warm Mexican (Nahuatl) terracotta/sand tones
/// paired with soft, calm pastels.
enum Theme {

    enum Palette {
        // Canvas & surfaces
        /// Warm cream app background.
        static let canvas = Color(hex: 0xFBF7F0)
        /// Card / elevated surface.
        static let surface = Color(hex: 0xFFFFFF)
        /// Recessed / secondary surface (sand).
        static let surfaceAlt = Color(hex: 0xF3ECE0)
        /// Hairline border / divider.
        static let hairline = Color(hex: 0xE7DDCD)

        // Text
        static let textPrimary = Color(hex: 0x3A332E)   // warm near-black
        static let textSecondary = Color(hex: 0x8A8077) // warm gray
        static let textOnAccent = Color(hex: 0xFFFFFF)

        // Brand accents
        /// Soft terracotta/coral — drives AccentColor.
        static let accent = Color(hex: 0xE0917F)
        /// Deeper terracotta for text/icons on light surfaces (accessible).
        static let accentDeep = Color(hex: 0xC2705C)
        /// Sage green — secondary accent.
        static let sage = Color(hex: 0x7FB59C)

        // Category pastels (medium-saturation so they read as both fills and small text)
        static let country = Color(hex: 0x7E97D6)   // periwinkle
        static let river = Color(hex: 0x53B7CE)     // aqua
        static let mountain = Color(hex: 0xB98A6E)  // warm clay
        static let sea = Color(hex: 0x4FB6A4)       // teal

        // Quiz / pile states
        static let correct = Color(hex: 0x6BAE78)
        static let wrong = Color(hex: 0xD9837A)
        static let new = Color(hex: 0x7FB59C)       // "new" pile (sage)
        static let pending = Color(hex: 0x7E9CD9)   // "due/pending" pile (soft blue)
        static let neutral = Color(hex: 0xB7AEA2)   // disabled / neutral
    }

    enum Metrics {
        static let cardRadius: CGFloat = 18
        static let tileRadius: CGFloat = 14
        static let pillRadius: CGFloat = 10
        static let cardShadowRadius: CGFloat = 10
    }

    /// Soft, diffuse card shadow tuned for the cream canvas.
    static let cardShadow = Color(hex: 0x6B5B47).opacity(0.10)
}

extension Color {
    /// Build a `Color` from a 24-bit RGB hex literal, e.g. `Color(hex: 0xE0917F)`.
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
