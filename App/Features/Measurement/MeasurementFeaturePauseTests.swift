import AppClients
import ComposableArchitecture
import Foundation
import Models
import PulseEngine
import PulseSourceClient
import SwiftUI
import Testing
@testable import FreePulseCheck

extension MeasurementFeatureTests {
    @MainActor
    @Suite internal struct Pause {
        @Test(arguments: [FingerState.absent, .partial, .saturated, .tooDark, .tooMuchPressure])
        internal func fingerNotPresentWhileMeasuringPauses(fingerState: FingerState) async {
            let clock = TestClock()
            let snapshots = LockIsolated(PulseSnapshot(fingerState: fingerState))
            let store = makeStore(measuringState(), snapshots: snapshots, clock: clock)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: fingerState)
                $0.phase = .paused
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.pausedSeconds = 1
            }

            await store.send(.scenePhaseChanged(.background)) {
                $0.phase = .failed(.interrupted)
            }
        }

        /**
         The finger leaves for 3 s, returns for 1 s, then leaves again.

         Expected: the countdown stops while paused and resumes on return, and paused time keeps accumulating.
         */
        @Test internal func pauseStopsTheCountdownAndResumeRestartsIt() async {
            let clock = TestClock()
            let snapshots = LockIsolated(PulseSnapshot(fingerState: .absent))
            let store = makeStore(measuringState(), snapshots: snapshots, clock: clock)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: .absent)
                $0.phase = .paused
            }
            for second in 1...3 {
                await clock.advance(by: .seconds(1))
                await store.receive(\.timerTicked) {
                    $0.pausedSeconds = second
                }
            }

            snapshots.setValue(lockedSnapshot)
            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = lockedSnapshot
                $0.phase = .measuring
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.remainingSeconds = 49
            }

            snapshots.setValue(PulseSnapshot(fingerState: .absent))
            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: .absent)
                $0.phase = .paused
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.pausedSeconds = 4
            }

            await store.send(.scenePhaseChanged(.background)) {
                $0.phase = .failed(.interrupted)
            }
        }

        @Test internal func pausedForMoreThanTenSecondsFailsWithFingerLifted() async {
            let clock = TestClock()
            let snapshots = LockIsolated(PulseSnapshot(fingerState: .absent))
            let store = makeStore(measuringState(), snapshots: snapshots, clock: clock)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: .absent)
                $0.phase = .paused
            }
            for second in 1...10 {
                await clock.advance(by: .seconds(1))
                await store.receive(\.timerTicked) {
                    $0.pausedSeconds = second
                }
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.pausedSeconds = 11
                $0.phase = .failed(.fingerLifted)
            }
        }

        @Test internal func pausedTimeAccumulatesAcrossPauses() async {
            let clock = TestClock()
            let snapshots = LockIsolated(PulseSnapshot(fingerState: .absent))
            var initialState = measuringState()
            initialState.pausedSeconds = 9
            let store = makeStore(initialState, snapshots: snapshots, clock: clock)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: .absent)
                $0.phase = .paused
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.pausedSeconds = 10
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.pausedSeconds = 11
                $0.phase = .failed(.fingerLifted)
            }
        }
    }
}
