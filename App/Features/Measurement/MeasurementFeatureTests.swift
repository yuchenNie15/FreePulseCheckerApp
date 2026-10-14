import AppClients
import ComposableArchitecture
import Foundation
import Models
import PulseEngine
import PulseSourceClient
import Testing
@testable import FreePulseCheck

/// Groups the measurement suites and holds the fixtures they share.
@Suite internal struct MeasurementFeatureTests {
    internal static let now = Date(timeIntervalSince1970: 1_800_000_000)

    internal static let frame = PPGFrame(timestamp: 0, cells: [])

    internal static let motionSample = MotionSample(timestamp: 0, magnitude: 1.4)

    internal static let lockedSnapshot = PulseSnapshot(
        fingerState: .present,
        bpm: 72,
        quality: .good,
        qualityScore: 0.9,
        waveform: [0, 0.5, 1, 0.5, 0]
    )

    internal static let summary = PulseSummary(
        bpm: 71,
        quality: .good,
        qualityScore: 0.88,
        hrv: nil,
        beatIntervals: [0.84, 0.85, 0.83],
        waveform: [0, 1, 0]
    )

    internal static let reading = PulseReading(id: UUID(7), date: now, summary: summary)

    internal static func state(_ phase: MeasurementFeature.Phase) -> MeasurementFeature.State {
        var state = MeasurementFeature.State(captureRate: 60)
        state.phase = phase
        return state
    }

    internal static func measuringState() -> MeasurementFeature.State {
        var state = Self.state(.measuring)
        state.remainingSeconds = 50
        state.analysis.snapshot = lockedSnapshot
        state.analysis.measuringStart = 0
        return state
    }

    @MainActor
    internal static func makeStore(
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
