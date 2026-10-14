import ComposableArchitecture
import Foundation
import PulseSourceClient

extension MeasurementFeature {
    private enum CancelID: Hashable, Sendable {
        case engine
        case timer
    }

    internal var engine: Effect<Action> {
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

    internal var timer: Effect<Action> {
        .run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.timerTicked)
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }

    internal var cancelAll: Effect<Action> {
        .merge(.cancel(id: CancelID.engine), .cancel(id: CancelID.timer))
    }

    internal var finish: Effect<Action> {
        .merge(cancelAll, .run { _ in await dismiss() })
    }

    internal func fail(_ state: inout State, _ reason: FailureReason) -> Effect<Action> {
        state.phase = .failed(reason)
        state.alert = nil
        return cancelAll
    }
}
