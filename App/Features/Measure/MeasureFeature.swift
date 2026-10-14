import AppClients
import ComposableArchitecture
import Models
import PulseSourceClient
import SwiftUI

@Reducer
internal struct MeasureFeature: Sendable {
    internal static let recentCount = 3

    @ObservableState
    internal struct State: Equatable, Sendable {
        @Shared internal var readings: IdentifiedArrayOf<PulseReading>
        @Shared internal var healthWarning: String?
        @Presents internal var measurement: MeasurementFeature.State?
        internal var isCameraDeniedPresented = false
        /// Reference point for the "Today" / "Yesterday" labels, refreshed on appear.
        internal var now: Date

        internal var recentReadings: [PulseReading] {
            Array(readings.prefix(MeasureFeature.recentCount))
        }

        /** - Parameter readings: Defaults to the saved readings; previews pass `Shared(value:)`.
        - Parameter healthWarning: Defaults to the app-wide warning key; previews pass `Shared(value:)`.
        - Parameter now: Placeholder until `onAppear` reads the current date. */
        internal init(
            readings: Shared<IdentifiedArrayOf<PulseReading>> = Shared(.readings),
            healthWarning: Shared<String?> = Shared(.healthWarning),
            now: Date = .distantPast
        ) {
            _readings = readings
            _healthWarning = healthWarning
            self.now = now
        }
    }

    internal enum Action: Equatable, Sendable {
        case cameraDeniedDismissed
        case cameraPermissionResponse(granted: Bool)
        case healthWarningDismissed
        case measurement(PresentationAction<MeasurementFeature.Action>)
        case onAppear
        case openSettingsTapped
        case readingTapped(PulseReading.ID)
        case seeAllTapped
        case startTapped
    }

    @Dependency(\.appNavigator) private var appNavigator
    @Dependency(\.cameraPermission) private var cameraPermission
    @Dependency(\.date) private var date
    @Dependency(\.openURL) private var openURL
    @Dependency(\.pulseSource) private var pulseSource

    internal init() {}

    internal var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cameraDeniedDismissed:
                state.isCameraDeniedPresented = false
                return .none

            case let .cameraPermissionResponse(granted):
                present(&state, granted: granted)
                return .none

            case .healthWarningDismissed:
                state.$healthWarning.withLock { $0 = nil }
                return .none

            case .measurement:
                return .none

            case .onAppear:
                state.now = date.now
                return .none

            case .openSettingsTapped:
                state.isCameraDeniedPresented = false
                return .run { _ in
                    let url = await MainActor.run { URL(string: UIApplication.openSettingsURLString) }
                    if let url {
                        await openURL(url)
                    }
                }

            case let .readingTapped(id):
                return .run { _ in appNavigator.showReading(id) }

            case .seeAllTapped:
                return .run { _ in appNavigator.showHistory() }

            case .startTapped:
                switch cameraPermission.status() {
                case .authorized:
                    present(&state, granted: true)
                    return .none
                case .denied:
                    present(&state, granted: false)
                    return .none
                case .notDetermined:
                    return .run { send in
                        await send(.cameraPermissionResponse(granted: cameraPermission.request()))
                    }
                }
            }
        }
        .ifLet(\.$measurement, action: \.measurement) { MeasurementFeature() }
    }

    private func present(_ state: inout State, granted: Bool) {
        if granted {
            state.measurement = MeasurementFeature.State(captureRate: pulseSource.captureRate())
        } else {
            state.isCameraDeniedPresented = true
        }
    }
}
