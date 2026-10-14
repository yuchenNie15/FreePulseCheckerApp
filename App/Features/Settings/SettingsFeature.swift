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

        internal init() {}
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
    @Dependency(\.openURL) private var openURL

    internal init() {}

    internal var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.appVersion = appInfo.version()
                state.healthAccess = healthKit.access()
                return .none

            case .authorizationCompleted, .sceneBecameActive:
                state.healthAccess = healthKit.access()
                return .none

            case .healthRowTapped:
                switch state.healthAccess {
                case .notDetermined:
                    return .run { send in
                        try await healthKit.requestAuthorization()
                        await send(.authorizationCompleted)
                    } catch: { _, _ in }
                case .authorized, .denied:
                    return .run { _ in
                        await openURL(Self.healthAppURL)
                    }
                case .unavailable, nil:
                    return .none
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
