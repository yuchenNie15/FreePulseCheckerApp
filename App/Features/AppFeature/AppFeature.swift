import AppClients
import ComposableArchitecture
import SwiftUI

@Reducer
internal struct AppFeature: Sendable {
    @ObservableState
    internal struct State: Equatable, Sendable {
        @Shared internal var selectedTab: AppTab
        internal var measure = MeasureFeature.State()
        internal var history = HistoryFeature.State()
        internal var settings = SettingsFeature.State()

        /// - Parameter selectedTab: Defaults to the app-wide key that `AppNavigator` writes; previews pass `Shared(value:)`.
        internal init(selectedTab: Shared<AppTab> = Shared(.selectedTab)) {
            _selectedTab = selectedTab
        }
    }

    internal enum Action: Equatable, Sendable {
        case history(HistoryFeature.Action)
        case measure(MeasureFeature.Action)
        case settings(SettingsFeature.Action)
        case tabSelected(AppTab)
    }

    @Dependency(\.log) private var log

    internal init() {}

    internal var body: some ReducerOf<Self> {
        Scope(\.measure, action: \.measure) { MeasureFeature() }
        Scope(\.history, action: \.history) { HistoryFeature() }
        Scope(\.settings, action: \.settings) { SettingsFeature() }
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.$selectedTab.withLock { $0 = tab }
                return log.debug(.app, "Tab selected: \(tab)")
            case .history, .measure, .settings:
                return .none
            }
        }
    }
}
