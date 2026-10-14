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
    @Suite internal struct Engine {
        @Test internal func firstEventLeavesPreparingAndEventsReachTheEngine() async {
            let (stream, continuation) = AsyncThrowingStream.makeStream(of: PulseSourceEvent.self, throwing: (any Error).self)
            let store = makeStore(MeasurementFeature.State(captureRate: 60)) {
                $0.pulseSource.events = { stream }
            }

            await store.send(.task)
            continuation.yield(.frame(frame))
            await store.receive(\.analysis.frame) {
                $0.phase = .waitingForFinger
            }
            continuation.yield(.motion(motionSample))
            // The motion log is engine-internal state that the test target can't construct.
            store.exhaustivity = .off(showSkippedAssertions: false)
            await store.receive(.analysis(.motion(motionSample)))
            store.exhaustivity = .on
            continuation.finish()
            await store.finish()
        }

        @Test(arguments: [
            (PulseSourceError.cameraUnavailable, MeasurementFeature.FailureReason.cameraUnavailable),
            (.configurationFailed, .cameraUnavailable),
            (.overheated, .overheated),
            (.interrupted, .interrupted),
        ])
        internal func engineErrorsFailWithMatchingReason(error: PulseSourceError, reason: MeasurementFeature.FailureReason) async {
            let store = makeStore(MeasurementFeature.State(captureRate: 60)) {
                $0.pulseSource.events = { AsyncThrowingStream { $0.finish(throwing: error) } }
            }

            await store.send(.task)
            await store.receive(.engineFailed(reason)) {
                $0.phase = .failed(reason)
            }
        }

        @Test internal func tryAgainResetsAndRestartsTheEngine() async {
            let (stream, continuation) = AsyncThrowingStream.makeStream(of: PulseSourceEvent.self, throwing: (any Error).self)
            var initialState = state(.failed(.unreliable))
            initialState.remainingSeconds = 12
            initialState.pausedSeconds = 4
            initialState.analysis.snapshot = lockedSnapshot
            let store = makeStore(initialState) {
                $0.pulseSource.events = { stream }
            }

            await store.send(.tryAgainTapped) {
                $0.phase = .preparing
                $0.remainingSeconds = 60
                $0.pausedSeconds = 0
            }
            await store.receive(\.analysis.reset) {
                $0.analysis = PulseAnalysis.State(captureRate: 60)
            }
            continuation.yield(.frame(frame))
            await store.receive(\.analysis.frame) {
                $0.phase = .waitingForFinger
            }
            continuation.finish()
            await store.finish()
        }
    }
}
