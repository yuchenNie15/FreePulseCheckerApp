import AppClients
import ComposableArchitecture
import DesignSystem
import HistoryFeature
import MeasureFeature
import SettingsFeature
import SwiftUI

@Reducer
public struct AppFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        @Shared(.selectedTab) public var selectedTab
        public var measure = MeasureFeature.State()
        public var history = HistoryFeature.State()
        public var settings = SettingsFeature.State()

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case history(HistoryFeature.Action)
        case measure(MeasureFeature.Action)
        case settings(SettingsFeature.Action)
        case tabSelected(AppTab)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
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

public struct AppView: View {
    @Bindable private var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
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
