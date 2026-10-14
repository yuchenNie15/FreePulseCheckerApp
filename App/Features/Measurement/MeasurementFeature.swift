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

    internal enum Phase: Equatable, Sendable {
        case preparing
        case waitingForFinger
        case calibrating
        case measuring
        case paused
        case result(PulseReading)
        case failed(FailureReason)
    }

    internal enum FailureReason: Equatable, Sendable {
        case fingerLifted
        case unreliable
        case cameraUnavailable
        case overheated
        case interrupted
    }

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

    private enum CancelID: Hashable, Sendable {
        case engine
        case timer
    }

    @Dependency(\.continuousClock) private var clock
    @Dependency(\.date.now) private var now
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.pulseAnalyzer) private var pulseAnalyzer
    @Dependency(\.pulseSource) private var pulseSource
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

    private var engine: Effect<Action> {
        .run { send in
            for try await event in await pulseSource.events() {
                switch event {
                case let .frame(frame):
                    await send(.analysis(.frame(frame)))
                case let .motion(sample):
                    await send(.analysis(.motion(sample)))
                }
            }
        } catch: { error, send in
            await send(.engineFailed(FailureReason(error)))
        }
        .cancellable(id: CancelID.engine, cancelInFlight: true)
    }

    private var timer: Effect<Action> {
        .run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.timerTicked)
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }

    private var cancelAll: Effect<Action> {
        .merge(.cancel(id: CancelID.engine), .cancel(id: CancelID.timer))
    }

    private var finish: Effect<Action> {
        .merge(cancelAll, .run { _ in await dismiss() })
    }

    private func fail(_ state: inout State, _ reason: FailureReason) -> Effect<Action> {
        state.phase = .failed(reason)
        state.alert = nil
        return cancelAll
    }

    private func transition(_ state: inout State) -> Effect<Action> {
        let snapshot = state.analysis.snapshot
        switch state.phase {
        case .preparing:
            state.phase = .waitingForFinger
            return .none

        case .waitingForFinger where snapshot.fingerState == .present:
            state.phase = .calibrating
            return .none

        case .calibrating where snapshot.fingerState == .absent:
            state.phase = .waitingForFinger
            return .none

        case .calibrating where snapshot.bpm != nil:
            state.phase = .measuring
            return .merge(.send(.analysis(.beginMeasuring)), timer)

        case .measuring where snapshot.fingerState != .present && state.remainingSeconds > 0:
            state.phase = .paused
            return timer

        case .paused where snapshot.fingerState == .present:
            state.phase = .measuring
            return timer

        default:
            return .none
        }
    }

    private func tick(_ state: inout State) -> Effect<Action> {
        switch state.phase {
        case .measuring:
            state.remainingSeconds -= 1
            guard state.remainingSeconds <= 0 else { return .none }
            return .merge(
                cancelAll,
                .run { [analysis = state.analysis] send in
                    let result = Result { try pulseAnalyzer.summarize(analysis) }
                        .mapError { _ in PulseAnalysisError.unreliable }
                    await send(.summaryFinished(result))
                }
            )

        case .paused:
            state.pausedSeconds += 1
            guard state.pausedSeconds > Self.maximumPausedSeconds else { return .none }
            return fail(&state, .fingerLifted)

        default:
            return .none
        }
    }
}

extension MeasurementFeature.Phase {
    /// The camera is running and no outcome exists yet.
    internal var isActive: Bool {
        switch self {
        case .preparing, .waitingForFinger, .calibrating, .measuring, .paused: true
        case .result, .failed: false
        }
    }

    internal var needsStopConfirmation: Bool {
        switch self {
        case .calibrating, .measuring, .paused: true
        case .preparing, .waitingForFinger, .result, .failed: false
        }
    }
}

extension MeasurementFeature.FailureReason {
    internal init(_ error: any Error) {
        switch error as? PulseSourceError {
        case .overheated: self = .overheated
        case .interrupted: self = .interrupted
        case .cameraUnavailable, .configurationFailed, nil: self = .cameraUnavailable
        }
    }
}

extension AlertState where Action == MeasurementFeature.Action.Alert {
    internal static var stopMeasuring: Self {
        AlertState {
            TextState("Stop measuring?")
        } actions: {
            ButtonState(role: .destructive, action: .stopTapped) {
                TextState("Stop")
            }
            ButtonState(role: .cancel) {
                TextState("Keep Measuring")
            }
        } message: {
            TextState("This reading won't be saved.")
        }
    }
}
