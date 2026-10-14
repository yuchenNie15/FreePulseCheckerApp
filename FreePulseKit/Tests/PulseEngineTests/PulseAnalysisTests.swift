import ComposableArchitecture
import Foundation
import Testing
@testable import PulseEngine

@MainActor
@Suite struct PulseAnalysisTests {
    /** 60 fps frames of a fingertip pulse with respiratory variability, ±3 ms frame jitter and sensor noise,
    measured for 60 s from the first BPM lock.

    Expected: BPM within ±2 of the truth, RMSSD and SDNN within ±5 ms, and Good quality. */
    @Test(arguments: [52.0, 75, 110])
    func measuresKnownHeartRateAndHRV(bpm: Double) throws {
        let ppg = SyntheticPPG(intervals: SyntheticPPG.intervals(bpm: bpm, duration: 90))
        let run = measure(ppg.frames(rate: 60, duration: 90))
        let start = try #require(run.measuringStart)
        let summary = try run.summary.get()

        let trueIntervals = ppg.intervals(from: start, through: start + 60)
        let trueBPM = 60 / (trueIntervals.reduce(0, +) / Double(trueIntervals.count))
        let hrv = try #require(summary.hrv)

        #expect(abs(Double(summary.bpm) - trueBPM) <= 2)
        #expect(abs(hrv.rmssd - rmssdMilliseconds(trueIntervals)) <= 5)
        #expect(abs(hrv.sdnn - sdnnMilliseconds(trueIntervals)) <= 5)
        #expect(summary.quality == .good)
        #expect(summary.waveform.count == 100)
        #expect(start < 15)
    }

    @Test func bareLensNeverReportsABPM() {
        let frames = (0..<(20 * 60)).map {
            PPGFrame(timestamp: Double($0) / 60, cells: SyntheticPPG.uniformCells(red: 120, green: 110))
        }
        #expect(measure(frames).snapshots.allSatisfy { $0.fingerState == .absent && $0.bpm == nil })
    }

    @Test func noiseMuchLargerThanThePulseIsNeverFair() {
        let ppg = SyntheticPPG(intervals: SyntheticPPG.intervals(bpm: 75, duration: 30))
        let run = measure(ppg.frames(rate: 60, duration: 30, noise: 25))
        #expect(run.snapshots.allSatisfy { $0.bpm == nil })
        #expect(run.measuringStart == nil)
    }

    @Test func constantMotionMakesTheMeasurementUnreliable() {
        let ppg = SyntheticPPG(intervals: SyntheticPPG.intervals(bpm: 75, duration: 90))
        let run = measure(ppg.frames(rate: 60, duration: 90), motionAfterLock: true)
        #expect(throws: PulseAnalysisError.unreliable) { try run.summary.get() }
    }

    @Test func liftingTheFingerReturnsToAbsent() {
        let ppg = SyntheticPPG(intervals: SyntheticPPG.intervals(bpm: 75, duration: 15))
        var state = PulseAnalysis.State(captureRate: 60)
        for frame in ppg.frames(rate: 60, duration: 15) {
            PulseAnalysis.ingest(frame, &state)
        }
        #expect(state.snapshot.fingerState == .present)
        for index in 0..<16 {
            let bare = PPGFrame(timestamp: 15 + Double(index) / 60, cells: SyntheticPPG.uniformCells(red: 120, green: 110))
            PulseAnalysis.ingest(bare, &state)
        }
        #expect(state.snapshot == PulseSnapshot(fingerState: .absent))
    }

    /** A store receives finger frames, then `beginMeasuring`, then `reset`.

    Expected: the snapshot reports the finger once the hysteresis completes, `beginMeasuring` records the
    latest frame time, and `reset` returns to the initial state. */
    @Test func reducerDrivesSnapshotAndMeasuringPhase() async {
        let store = TestStore(initialState: PulseAnalysis.State(captureRate: 60)) {
            PulseAnalysis()
        } withDependencies: {
            $0.pulseAnalyzer = .liveValue
        }
        store.exhaustivity = .off

        let frames = (0..<20).map {
            PPGFrame(timestamp: Double($0) / 60, cells: SyntheticPPG.uniformCells(red: 200, green: 70))
        }
        for frame in frames {
            await store.send(.frame(frame))
        }
        #expect(store.state.fingerState == .present)

        await store.send(.beginMeasuring) {
            $0.measuringStart = frames.last?.timestamp
        }
        await store.send(.reset) {
            $0 = PulseAnalysis.State(captureRate: 60)
        }
    }

    @Test func reducerDelegatesFramesToTheAnalyzerDependency() async {
        let scripted = PulseSnapshot(fingerState: .present, bpm: 72, quality: .good, qualityScore: 0.9)
        let store = TestStore(initialState: PulseAnalysis.State(captureRate: 60)) {
            PulseAnalysis()
        } withDependencies: {
            $0.pulseAnalyzer.ingest = { _, state in state.snapshot = scripted }
        }
        await store.send(.frame(PPGFrame(timestamp: 0, cells: []))) {
            $0.snapshot = scripted
        }
    }

    private struct Run {
        var snapshots: [PulseSnapshot]
        var measuringStart: TimeInterval?
        var summary: Result<PulseSummary, PulseAnalysisError>
    }

    /// Mirrors the app: reads the snapshot at 4 Hz, starts measuring at the first BPM, and stops 60 s later.
    private func measure(_ frames: [PPGFrame], motionAfterLock: Bool = false) -> Run {
        var state = PulseAnalysis.State(captureRate: 60)
        var snapshots: [PulseSnapshot] = []
        for (index, frame) in frames.enumerated() {
            if motionAfterLock, state.measuringStart != nil, index.isMultiple(of: 3) {
                MotionLog.record(MotionSample(timestamp: frame.timestamp, magnitude: 1.2), &state.motion)
            }
            PulseAnalysis.ingest(frame, &state)
            guard index.isMultiple(of: 15) else { continue }
            snapshots.append(state.snapshot)
            if state.measuringStart == nil, state.snapshot.bpm != nil {
                state.measuringStart = frame.timestamp
            }
            if let start = state.measuringStart, frame.timestamp - start >= 60 { break }
        }
        let summary = Result<PulseSummary, PulseAnalysisError> { [state] () throws(PulseAnalysisError) in
            try state.summarize()
        }
        return Run(snapshots: snapshots, measuringStart: state.measuringStart, summary: summary)
    }
}
