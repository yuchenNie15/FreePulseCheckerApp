import ComposableArchitecture
import SwiftUI

/// Hosts Settings screens in a store-driven `NavigationStack`, as `SettingsView` does, so `NavigationLink(state:)` rows are presentable in previews.
internal struct SettingsNavigationPreview<Content: View>: View {
    @State private var store = Store(initialState: SettingsFeature.State()) { SettingsFeature() }
    private let content: Content

    internal init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    internal var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            content
        } destination: { _ in
            EmptyView()
        }
    }
}
