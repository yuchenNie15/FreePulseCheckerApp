import PreviewSnapshots
import SwiftUI

/** Named states a view renders in, shared by its Xcode previews and its snapshot test.
- Declare one per view as `static var snapshots` on its `PreviewProvider`, and return `snapshots.previews` from `previews`.
- Every configuration renders in dark mode, the app's only appearance. */
@MainActor
public struct AppPreviewSnapshots<State> {
    public struct Configuration {
        public let name: String
        public let state: State

        public init(name: String, state: State) {
            self.name = name
            self.state = state
        }
    }

    public let configurations: [Configuration]
    public let configure: @MainActor (State) -> AnyView

    public init<V: View>(configurations: [Configuration], configure: @escaping @MainActor (State) -> V) {
        self.configurations = configurations
        self.configure = { AnyView(configure($0).preferredColorScheme(.dark)) }
    }

    public var previews: some View {
        ForEach(configurations, id: \.name) { configuration in
            configure(configuration.state).previewDisplayName(configuration.name)
        }
    }

    /// The same configurations as a DoorDash `PreviewSnapshots`, for tools built on that library.
    public var previewSnapshots: PreviewSnapshots<State> {
        let configure = configure
        return PreviewSnapshots(
            configurations: configurations.map { .init(name: $0.name, state: $0.state) },
            configure: { state in MainActor.assumeIsolated { MainActorBox(view: configure(state)) }.view }
        )
    }
}

/// Carries a view out of `MainActor.assumeIsolated`; it is created and consumed on the main actor.
private struct MainActorBox: @unchecked Sendable {
    let view: AnyView
}
