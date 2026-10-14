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
    @Suite internal struct Calibration {
        @Test internal func presentFingerStartsCalibrating() async {
            let snapshots = LockIsolated(PulseSnapshot(fingerState: .present))
            let store = makeStore(state(.waitingForFinger), snapshots: snapshots)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: .present)
                $0.phase = .calibrating
            }
        }

        @Test internal func phaseChangeIsLogged() async {
            let entries = LockIsolated<[LogEntry]>([])
            let snapshots = LockIsolated(PulseSnapshot(fingerState: .present))
            let store = makeStore(state(.waitingForFinger), snapshots: snapshots) {
                $0.log.write = { entry in entries.withValue { $0.append(entry) } }
            }

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: .present)
                $0.phase = .calibrating
            }
            await store.finish()

            #expect(entries.value == [LogEntry(.info, .measurement, "Phase waitingForFinger -> calibrating")])
        }

        @Test(arguments: [FingerState.partial, .saturated, .tooDark, .tooMuchPressure])
        internal func fingerNotPresentKeepsWaiting(fingerState: FingerState) async {
            let snapshots = LockIsolated(PulseSnapshot(fingerState: fingerState))
            let store = makeStore(state(.waitingForFinger), snapshots: snapshots)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: fingerState)
            }
        }

        @Test internal func liftingTheFingerWhileCalibratingReturnsToWaiting() async {
            let snapshots = LockIsolated(PulseSnapshot(fingerState: .absent))
            var initialState = state(.calibrating)
            initialState.analysis.snapshot = PulseSnapshot(fingerState: .present)
            let store = makeStore(initialState, snapshots: snapshots)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: .absent)
                $0.phase = .waitingForFinger
            }
        }

        @Test internal func calibratingWithoutABPMKeepsCalibrating() async {
            let snapshots = LockIsolated(PulseSnapshot(fingerState: .present, quality: .poor, qualityScore: 0.2))
            let store = makeStore(state(.calibrating), snapshots: snapshots)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = PulseSnapshot(fingerState: .present, quality: .poor, qualityScore: 0.2)
            }
        }

        @Test internal func firstBPMStartsMeasuringAndTheCountdown() async {
            let clock = TestClock()
            let snapshots = LockIsolated(lockedSnapshot)
            let store = makeStore(state(.calibrating), snapshots: snapshots, clock: clock)

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = lockedSnapshot
                $0.phase = .measuring
            }
            await store.receive(\.analysis.beginMeasuring) {
                $0.analysis.measuringStart = 0
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.remainingSeconds = 59
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.remainingSeconds = 58
            }

            await store.send(.scenePhaseChanged(.background)) {
                $0.phase = .failed(.interrupted)
            }
        }
    }
}
