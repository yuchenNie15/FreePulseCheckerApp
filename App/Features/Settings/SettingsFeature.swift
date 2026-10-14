import AppClients
import ComposableArchitecture
import Foundation
import HealthKitClient

@Reducer
internal struct SettingsFeature: Sendable {
    @Reducer
    internal enum Path {
        case disclaimer
        case licenses
        @ReducerCaseIgnored
        case license(License)
    }

    @ObservableState
    internal struct State: Equatable, Sendable {
        /// "0.1 (1)", loaded on `.task`.
        internal var appVersion: String?
        /// Nil until the first refresh.
        internal var healthAccess: HealthAccess?
        internal var path = StackState<Path.State>()

        internal init(appVersion: String? = nil, healthAccess: HealthAccess? = nil) {
            self.appVersion = appVersion
            self.healthAccess = healthAccess
        }
    }

    internal enum Action: Equatable, Sendable {
        case authorizationCompleted
        case healthRowTapped
        case path(StackActionOf<Path>)
        case sceneBecameActive
        case task
    }

    @Dependency(\.appInfo) private var appInfo
    @Dependency(\.healthKit) private var healthKit
    @Dependency(\.log) private var log
    @Dependency(\.openURL) private var openURL

    internal init() {}

    internal var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.appVersion = appInfo.version()
                state.healthAccess = healthKit.access()
                return log.debug(.settings, "Loaded version \(state.appVersion ?? "unknown"), Health \(String(describing: state.healthAccess))")

            case .authorizationCompleted, .sceneBecameActive:
                state.healthAccess = healthKit.access()
                return log.debug(.settings, "Health access refreshed: \(String(describing: state.healthAccess))")

            case .healthRowTapped:
                switch state.healthAccess {
                case .notDetermined:
                    return .merge(
                        log.info(.settings, "Requesting Health authorization"),
                        .run { send in
                            try await healthKit.requestAuthorization()
                            await send(.authorizationCompleted)
                        } catch: { error, _ in
                            log.write(LogEntry(.error, .settings, "Health authorization failed: \(error)"))
                        }
                    )
                case .authorized, .denied:
                    return .merge(
                        log.info(.settings, "Opening the Health app"),
                        .run { _ in
                            await openURL(Self.healthAppURL)
                        }
                    )
                case .unavailable, nil:
                    return log.info(.settings, "Health row tapped but Health is unavailable")
                }

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    private static let healthAppURL = URL(string: "x-apple-health://")!
}

extension SettingsFeature.Path.State: Equatable, Sendable {}
extension SettingsFeature.Path.Action: Equatable, Sendable {}
