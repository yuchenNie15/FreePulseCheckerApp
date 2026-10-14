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
    @Suite internal struct Close {
        @Test(arguments: [MeasurementFeature.Phase.calibrating, .measuring, .paused])
        internal func closingMidReadingAsksForConfirmation(phase: MeasurementFeature.Phase) async {
            let dismissed = LockIsolated(false)
            let store = makeStore(state(phase)) {
                $0.dismiss = DismissEffect { dismissed.setValue(true) }
            }

            await store.send(.closeTapped) {
                $0.alert = .stopMeasuring
            }
            await store.send(.alert(.dismiss)) {
                $0.alert = nil
            }
            #expect(!dismissed.value)

            await store.send(.closeTapped) {
                $0.alert = .stopMeasuring
            }
            await store.send(.alert(.presented(.stopTapped))) {
                $0.alert = nil
            }
            await store.finish()
            #expect(dismissed.value)
        }

        @Test(arguments: [
            MeasurementFeature.Phase.preparing,
            .waitingForFinger,
            .failed(.unreliable),
            .result(PulseReading(id: UUID(0), date: Date(timeIntervalSince1970: 0), summary: summary)),
        ])
        internal func closingOutsideAReadingDismissesImmediately(phase: MeasurementFeature.Phase) async {
            let dismissed = LockIsolated(false)
            let store = makeStore(state(phase)) {
                $0.dismiss = DismissEffect { dismissed.setValue(true) }
            }

            await store.send(.closeTapped)
            await store.finish()

            #expect(dismissed.value)
        }

        @Test(arguments: [
            MeasurementFeature.Phase.preparing,
            .waitingForFinger,
            .calibrating,
            .measuring,
            .paused,
        ])
        internal func backgroundingMidReadingFailsAsInterrupted(phase: MeasurementFeature.Phase) async {
            var initialState = state(phase)
            initialState.alert = phase.needsStopConfirmation ? .stopMeasuring : nil
            let store = makeStore(initialState)

            await store.send(.scenePhaseChanged(.background)) {
                $0.phase = .failed(.interrupted)
                $0.alert = nil
            }
        }

        @Test internal func backgroundingAfterAResultChangesNothing() async {
            let store = makeStore(state(.result(reading)))

            await store.send(.scenePhaseChanged(.inactive))
            await store.send(.scenePhaseChanged(.background))
        }
    }
}
