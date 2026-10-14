import ComposableArchitecture
import SwiftUI

@main
internal struct FreePulseCheckApp: App {
    /// Static so SwiftUI previews, which re-create the entry point, don't create a second store.
    @MainActor private static let store = Store(initialState: AppFeature.State()) { AppFeature() }

    internal var body: some Scene {
        WindowGroup {
            if isTesting {
                EmptyView()
            } else {
                AppView(store: Self.store)
            }
        }
    }
}
