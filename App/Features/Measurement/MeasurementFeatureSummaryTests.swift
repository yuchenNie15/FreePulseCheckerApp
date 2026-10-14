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
    @Suite internal struct Summary {
        @Test internal func countdownReachingZeroSummarizesIntoAResult() async {
            let clock = TestClock()
            let snapshots = LockIsolated(lockedSnapshot)
            let summarized = LockIsolated<PulseAnalysis.State?>(nil)
            var initialState = state(.calibrating)
            initialState.remainingSeconds = 2
            let store = makeStore(initialState, snapshots: snapshots, clock: clock) {
                $0.pulseAnalyzer.summarize = { analysis in
                    summarized.setValue(analysis)
                    return summary
                }
            }

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = lockedSnapshot
                $0.phase = .measuring
            }
            await store.receive(\.analysis.beginMeasuring) {
                $0.analysis.measuringStart = 0
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.remainingSeconds = 1
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.remainingSeconds = 0
            }
            await store.receive(\.summaryFinished.success) {
                $0.phase = .result(PulseReading(id: UUID(0), date: now, summary: summary))
            }
            #expect(summarized.value?.measuringStart == 0)
        }

        @Test internal func unreliableSummaryFails() async {
            let clock = TestClock()
            let snapshots = LockIsolated(lockedSnapshot)
            var initialState = state(.calibrating)
            initialState.remainingSeconds = 1
            let store = makeStore(initialState, snapshots: snapshots, clock: clock) {
                $0.pulseAnalyzer.summarize = { _ in throw PulseAnalysisError.unreliable }
            }

            await store.send(.analysis(.frame(frame))) {
                $0.analysis.snapshot = lockedSnapshot
                $0.phase = .measuring
            }
            await store.receive(\.analysis.beginMeasuring) {
                $0.analysis.measuringStart = 0
            }
            await clock.advance(by: .seconds(1))
            await store.receive(\.timerTicked) {
                $0.remainingSeconds = 0
            }
            await store.receive(.summaryFinished(.failure(.unreliable))) {
                $0.phase = .failed(.unreliable)
            }
        }
    }
}
