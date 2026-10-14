import ComposableArchitecture
import DesignSystem
import Foundation
import Models
import PulseEngine
import SwiftUI

/// Fixed sample data for the measurement screens' previews and snapshot tests.
internal enum MeasurementScreensPreviewFixtures {
    internal static let date = Date(timeIntervalSince1970: 1_791_967_260)

    /// 4 s of a 74 BPM pulse at 30 fps: a systolic peak and a smaller dicrotic wave per beat, scaled to -1...1.
    internal static let waveform: [Double] = {
        let beatPeriod = 60.0 / 74.0
        let raw = (0..<120).map { index in
            let phase = (Double(index) / 30).truncatingRemainder(dividingBy: beatPeriod) / beatPeriod
            return gaussian(phase, center: 0.18, width: 0.06) + 0.35 * gaussian(phase, center: 0.48, width: 0.08)
        }
        let low = raw.min() ?? 0
        let high = raw.max() ?? 1
        return raw.map { ($0 - low) / (high - low) * 2 - 1 }
    }()

    internal static let goodReading = PulseReading(
        id: UUID(1),
        date: date,
        bpm: 74,
        rmssd: 42,
        sdnn: 48,
        quality: .good,
        qualityScore: 0.86,
        beatIntervals: Array(repeating: 60.0 / 74.0, count: 60),
        waveform: Array(waveform.prefix(100))
    )

    internal static let fairReadingWithoutHRV = PulseReading(
        id: UUID(2),
        date: date,
        bpm: 81,
        rmssd: nil,
        sdnn: nil,
        quality: .fair,
        qualityScore: 0.55,
        beatIntervals: Array(repeating: 60.0 / 81.0, count: 20),
        waveform: Array(waveform.prefix(100))
    )

    internal static let poorReading = PulseReading(
        id: UUID(3),
        date: date,
        bpm: 68,
        rmssd: nil,
        sdnn: nil,
        quality: .poor,
        qualityScore: 0.31,
        beatIntervals: Array(repeating: 60.0 / 68.0, count: 12),
        waveform: Array(waveform.prefix(100))
    )

    internal static let threeDigitReading = PulseReading(
        id: UUID(4),
        date: date,
        bpm: 142,
        rmssd: 18,
        sdnn: 22,
        quality: .good,
        qualityScore: 0.78,
        beatIntervals: Array(repeating: 60.0 / 142.0, count: 120),
        waveform: Array(waveform.prefix(100))
    )

    internal static func snapshot(
        fingerState: FingerState = .present,
        bpm: Int? = 74,
        quality: SignalQuality? = .good
    ) -> PulseSnapshot {
        PulseSnapshot(fingerState: fingerState, bpm: bpm, quality: quality, qualityScore: nil, waveform: waveform)
    }

    private static func gaussian(_ x: Double, center: Double, width: Double) -> Double {
        exp(-pow((x - center) / width, 2) / 2)
    }
}

extension View {
    /// Fills a screen-sized preview with the app background, as `MeasurementView` does.
    internal func measurementScreenPreview() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
    }

    /// Pads a component preview on the app background at a phone's content width.
    internal func measurementComponentPreview(width: CGFloat = 358) -> some View {
        frame(width: width)
            .padding(Metrics.screenMargin)
            .background(Color.background)
    }
}
