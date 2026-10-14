import AppClients
import ComposableArchitecture
import Foundation
import Models
import PulseEngine
import PulseSourceClient
import SwiftUI
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasurementFeatureTests {
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

    @Test internal func presentFingerStartsCalibrating() async {
        let snapshots = LockIsolated(PulseSnapshot(fingerState: .present))
        let store = makeStore(state(.waitingForFinger), snapshots: snapshots)

        await store.send(.analysis(.frame(frame))) {
            $0.analysis.snapshot = PulseSnapshot(fingerState: .present)
            $0.phase = .calibrating
        }
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

    @Test internal func saveStoresTheReadingWithHealthAndDismisses() async {
        let saves = LockIsolated<[SaveCall]>([])
        let dismissed = LockIsolated(false)
        let store = makeStore(state(.result(reading))) {
            $0.readingStore.save = { reading, saveToHealth in
                saves.withValue { $0.append(SaveCall(reading: reading, saveToHealth: saveToHealth)) }
            }
            $0.dismiss = DismissEffect { dismissed.setValue(true) }
        }

        await store.send(.saveTapped)
        await store.finish()

        #expect(saves.value == [SaveCall(reading: reading, saveToHealth: true)])
        #expect(dismissed.value)
    }

    @Test internal func turningHealthOffSavesOnlyLocally() async {
        let saves = LockIsolated<[SaveCall]>([])
        let store = makeStore(state(.result(reading))) {
            $0.readingStore.save = { reading, saveToHealth in
                saves.withValue { $0.append(SaveCall(reading: reading, saveToHealth: saveToHealth)) }
            }
            $0.dismiss = DismissEffect {}
        }

        await store.send(.binding(.set(\.saveToHealth, false))) {
            $0.saveToHealth = false
        }
        await store.send(.saveTapped)
        await store.finish()

        #expect(saves.value == [SaveCall(reading: reading, saveToHealth: false)])
    }

    @Test internal func discardDismissesWithoutSaving() async {
        let dismissed = LockIsolated(false)
        let store = makeStore(state(.result(reading))) {
            $0.dismiss = DismissEffect { dismissed.setValue(true) }
        }

        await store.send(.discardTapped)
        await store.finish()

        #expect(dismissed.value)
    }

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

    private func makeStore(
        _ initialState: MeasurementFeature.State,
        snapshots: LockIsolated<PulseSnapshot> = LockIsolated(PulseSnapshot(fingerState: .absent)),
        clock: TestClock<Duration> = TestClock(),
        dependencies: (inout DependencyValues) -> Void = { _ in }
    ) -> TestStoreOf<MeasurementFeature> {
        TestStore(initialState: initialState) {
            MeasurementFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.date.now = now
            $0.uuid = .incrementing
            $0.pulseAnalyzer.ingest = { _, state in state.snapshot = snapshots.value }
            dependencies(&$0)
        }
    }
}

private struct SaveCall: Equatable, Sendable {
    internal let reading: PulseReading
    internal let saveToHealth: Bool
}

private let now = Date(timeIntervalSince1970: 1_800_000_000)

private let frame = PPGFrame(timestamp: 0, cells: [])

private let motionSample = MotionSample(timestamp: 0, magnitude: 1.4)

private let lockedSnapshot = PulseSnapshot(
    fingerState: .present,
    bpm: 72,
    quality: .good,
    qualityScore: 0.9,
    waveform: [0, 0.5, 1, 0.5, 0]
)

private let summary = PulseSummary(
    bpm: 71,
    quality: .good,
    qualityScore: 0.88,
    hrv: nil,
    beatIntervals: [0.84, 0.85, 0.83],
    waveform: [0, 1, 0]
)

private let reading = PulseReading(id: UUID(7), date: now, summary: summary)

private func state(_ phase: MeasurementFeature.Phase) -> MeasurementFeature.State {
    var state = MeasurementFeature.State(captureRate: 60)
    state.phase = phase
    return state
}

private func measuringState() -> MeasurementFeature.State {
    var state = state(.measuring)
    state.remainingSeconds = 50
    state.analysis.snapshot = lockedSnapshot
    state.analysis.measuringStart = 0
    return state
}
