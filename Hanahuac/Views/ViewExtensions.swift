import SwiftUI

extension View {
    /// `.navigationBarTitleDisplayMode(.inline)` — no-op on macOS.
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
            navigationBarTitleDisplayMode(.inline)
        #else
            self
        #endif
    }

    /// `.navigationBarTitleDisplayMode(.large)` — no-op on macOS.
    func largeNavigationTitle() -> some View {
        #if os(iOS)
            navigationBarTitleDisplayMode(.large)
        #else
            self
        #endif
    }

    /// `.textInputAutocapitalization(.never)` — no-op on macOS.
    func neverAutocapitalize() -> some View {
        #if os(iOS)
            textInputAutocapitalization(.never)
        #else
            self
        #endif
    }
}
