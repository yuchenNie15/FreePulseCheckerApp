import AppClients
import ComposableArchitecture
import DesignSystem
import SwiftUI

internal struct AppView: View {
    @Bindable private var store: StoreOf<AppFeature>

    internal init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    internal var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
            Tab("Measure", systemImage: "heart.fill", value: AppTab.measure) {
                MeasureView(store: store.scope(\.measure, action: \.measure))
            }
            Tab("History", systemImage: "list.bullet", value: AppTab.history) {
                HistoryView(store: store.scope(\.history, action: \.history))
            }
            Tab("Settings", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView(store: store.scope(\.settings, action: \.settings))
            }
        }
        .tint(.accentStart)
        .preferredColorScheme(.dark)
    }
}

internal struct AppView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<AppTab> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Measure", state: .measure),
                .init(name: "History", state: .history),
                .init(name: "Settings", state: .settings),
            ],
            configure: { tab in
                AppView(store: Store(initialState: AppFeature.State(selectedTab: Shared(value: tab))) { EmptyReducer() })
            }
        )
    }
}
