import AppClients
import ComposableArchitecture
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct AppFeatureTests {
    @Test internal func selectingATabUpdatesTheSelection() async {
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() }
        await store.send(.tabSelected(.settings)) {
            $0.$selectedTab.withLock { $0 = .settings }
        }
    }

    @Test internal func navigatorChangesAreReflectedInTheSelectedTab() async {
        let store = TestStore(initialState: AppFeature.State()) { AppFeature() }
        AppNavigator.liveValue.showHistory()
        #expect(store.state.selectedTab == .history)
    }
}
