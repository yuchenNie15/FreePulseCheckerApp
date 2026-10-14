import AppFeature
import ComposableArchitecture
import SwiftUI

@main
internal struct FreePulseCheckApp: App {
    @MainActor private static let store = Store(initialState: AppFeature.State()) { AppFeature() }

    internal var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
