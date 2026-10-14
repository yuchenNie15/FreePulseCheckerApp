import AppClients
import ComposableArchitecture
import Foundation
import Models
import PulseEngine
import PulseSourceClient
import SwiftUI

@Reducer
internal struct MeasurementFeature: Sendable {
    internal static let duration = 60
    internal static let maximumPausedSeconds = 10

    @ObservableState
    internal struct State: Equatable, Sendable {
        internal var analysis: PulseAnalysis.State
        internal var phase = Phase.preparing
        internal var remainingSeconds = MeasurementFeature.duration
        internal var pausedSeconds = 0
        internal var saveToHealth = true
        @Presents internal var alert: AlertState<Action.Alert>?

        internal init(captureRate: Double) {
            analysis = PulseAnalysis.State(captureRate: captureRate)
        }
    }

    internal enum Action: BindableAction, Equatable, Sendable {
        case alert(PresentationAction<Alert>)
        case analysis(PulseAnalysis.Action)
        case binding(BindingAction<State>)
        case closeTapped
        case discardTapped
        case engineFailed(FailureReason)
        case saveTapped
        case scenePhaseChanged(ScenePhase)
        case summaryFinished(Result<PulseSummary, PulseAnalysisError>)
        case task
        case timerTicked
        case tryAgainTapped

        @CasePathable
        internal enum Alert: Equatable, Sendable {
            case stopTapped
        }
    }

    @Dependency(\.continuousClock) internal var clock
    @Dependency(\.date.now) private var now
    @Dependency(\.dismiss) internal var dismiss
    @Dependency(\.pulseAnalyzer) internal var pulseAnalyzer
    @Dependency(\.pulseSource) internal var pulseSource
    @Dependency(\.readingStore) private var readingStore
    @Dependency(\.uuid) private var uuid

    internal init() {}

    internal var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(\.analysis, action: \.analysis) { PulseAnalysis() }
        Reduce { state, action in
            switch action {
            case .alert(.presented(.stopTapped)):
                return finish

            case .alert, .binding:
                return .none

            case .analysis(.frame):
                return transition(&state)

            case .analysis:
                return .none

            case .closeTapped:
                if state.phase.needsStopConfirmation {
                    state.alert = .stopMeasuring
                    return .none
                }
                return finish

            case .discardTapped:
                return finish

            case let .engineFailed(reason):
                return fail(&state, reason)

            case .saveTapped:
                guard case let .result(reading) = state.phase else { return .none }
                return .run { [saveToHealth = state.saveToHealth] _ in
                    await readingStore.save(reading, saveToHealth)
                    await dismiss()
                }

            case let .scenePhaseChanged(scenePhase):
                guard scenePhase == .background, state.phase.isActive else { return .none }
                return fail(&state, .interrupted)

            case let .summaryFinished(.success(summary)):
                state.phase = .result(PulseReading(id: uuid(), date: now, summary: summary))
                return .none

            case .summaryFinished(.failure):
                state.phase = .failed(.unreliable)
                return .none

            case .task:
                return engine

            case .timerTicked:
                return tick(&state)

            case .tryAgainTapped:
                state.phase = .preparing
                state.remainingSeconds = Self.duration
                state.pausedSeconds = 0
                return .concatenate(.send(.analysis(.reset)), engine)
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
