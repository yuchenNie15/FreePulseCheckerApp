import ComposableArchitecture
import PulseEngine

extension MeasurementFeature {
    internal func transition(_ state: inout State) -> Effect<Action> {
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

    internal func tick(_ state: inout State) -> Effect<Action> {
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
