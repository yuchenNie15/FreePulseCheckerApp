import ComposableArchitecture
import Foundation
import Models
import PulseEngine

/// Fixed sample data for the measurement flow's previews and snapshot tests.
internal enum MeasurementFlowPreviewFixtures {
    internal static let captureRate = 60.0
    internal static let date = Date(timeIntervalSince1970: 1_791_967_260)
    internal static let readingID = UUID(uuidString: "6F1C2B0E-3D4A-4E5F-8A9B-0C1D2E3F4A5B")!

    internal static let liveWaveform: [Double] = (0..<120).map { pulse(at: Double($0) / 30) }

    internal static let reading = PulseReading(
        id: readingID,
        date: date,
        bpm: 72,
        rmssd: 42,
        sdnn: 51,
        quality: .good,
        qualityScore: 0.86,
        beatIntervals: [0.83, 0.84, 0.82, 0.85, 0.83, 0.84],
        waveform: (0..<100).map { pulse(at: Double($0) / 20) }
    )

    internal static let measuringSnapshot = PulseSnapshot(
        fingerState: .present,
        bpm: 72,
        quality: .good,
        qualityScore: 0.86,
        waveform: liveWaveform
    )

    internal static func state(
        phase: MeasurementFeature.Phase,
        snapshot: PulseSnapshot = PulseSnapshot(fingerState: .absent),
        remainingSeconds: Int = MeasurementFeature.duration,
        alert: AlertState<MeasurementFeature.Action.Alert>? = nil
    ) -> MeasurementFeature.State {
        var state = MeasurementFeature.State(captureRate: captureRate)
        state.phase = phase
        state.analysis.snapshot = snapshot
        state.remainingSeconds = remainingSeconds
        state.alert = alert
        return state
    }

    /// A 72 BPM pulse shape scaled to -1...1.
    private static func pulse(at seconds: Double) -> Double {
        let phase = seconds * 1.2 * 2 * .pi
        return 0.8 * sin(phase) + 0.2 * sin(2 * phase)
    }
}
