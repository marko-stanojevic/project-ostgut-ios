import SwiftUI

extension View {
    @ViewBuilder
    func emailInputModifiers() -> some View {
#if os(iOS)
        self
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
#else
        self
#endif
    }

    @ViewBuilder
    func navigationBarLargeTitle() -> some View {
#if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
#else
        self
#endif
    }

    @ViewBuilder
    func navigationBarInlineTitle() -> some View {
#if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }
}
