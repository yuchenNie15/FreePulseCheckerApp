import ComposableArchitecture
import Models

/// Cross-tab navigation, so features route without delegate actions to their parent.
@DependencyClient
public struct AppNavigator: Sendable {
    public var showHistory: @Sendable () -> Void
    public var showReading: @Sendable (_ id: PulseReading.ID) -> Void
}

extension AppNavigator: DependencyKey {
    public static let liveValue = AppNavigator(
        showHistory: {
            @Shared(.selectedTab) var selectedTab
            $selectedTab.withLock { $0 = .history }
        },
        showReading: { id in
            @Shared(.selectedTab) var selectedTab
            @Shared(.selectedReadingID) var selectedReadingID
            $selectedTab.withLock { $0 = .history }
            $selectedReadingID.withLock { $0 = id }
        }
    )

    public static let testValue = AppNavigator()
}

extension DependencyValues {
    public var appNavigator: AppNavigator {
        get { self[AppNavigator.self] }
        set { self[AppNavigator.self] = newValue }
    }
}
