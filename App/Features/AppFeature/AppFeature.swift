import AppClients
import ComposableArchitecture
import DesignSystem
import SwiftUI

@Reducer
internal struct AppFeature: Sendable {
    @ObservableState
    internal struct State: Equatable, Sendable {
        @Shared(.selectedTab) internal var selectedTab
        internal var measure = MeasureFeature.State()
        internal var history = HistoryFeature.State()
        internal var settings = SettingsFeature.State()

        internal init() {}
    }

    internal enum Action: Equatable, Sendable {
        case history(HistoryFeature.Action)
        case measure(MeasureFeature.Action)
        case settings(SettingsFeature.Action)
        case tabSelected(AppTab)
    }

    internal init() {}

    internal var body: some ReducerOf<Self> {
        Scope(\.measure, action: \.measure) { MeasureFeature() }
        Scope(\.history, action: \.history) { HistoryFeature() }
        Scope(\.settings, action: \.settings) { SettingsFeature() }
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.$selectedTab.withLock { $0 = tab }
                return .none
            case .history, .measure, .settings:
                return .none
            }
        }
    }
}

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
