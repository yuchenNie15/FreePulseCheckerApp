import Foundation
import Models
import PulseEngine

/// Fixed dates, calendar and readings shared by previews and snapshot tests.
internal enum PreviewFixtures {
    /// 2026-10-14 09:41 UTC.
    internal static let now = Date(timeIntervalSince1970: 1_791_967_260)

    internal static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    internal static let componentWidth: Double = 358

    internal static let flatWaveform = [Double](repeating: 0, count: 100)

    /// Four beats, each a systolic peak followed by a smaller dicrotic wave.
    internal static let pulseWaveform: [Double] = (0..<100).map { index in
        let x = Double(index)
        let value = [12.0, 37, 62, 87].reduce(-0.6) { sum, beat in
            sum + 1.5 * exp(-pow((x - beat) / 2.5, 2)) + 0.4 * exp(-pow((x - beat - 8) / 4, 2))
        }
        return min(max(value, -1), 1)
    }

    internal static func reading(
        bpm: Int = 72,
        rmssd: Double? = 42,
        sdnn: Double? = 51,
        quality: SignalQuality = .good,
        date: Date = now,
        waveform: [Double] = pulseWaveform
    ) -> PulseReading {
        PulseReading(
            id: UUID(uuidString: "6F1C2B9E-3A4D-4E5F-8A7B-1C2D3E4F5A6B")!,
            date: date,
            bpm: bpm,
            rmssd: rmssd,
            sdnn: sdnn,
            quality: quality,
            qualityScore: quality == .good ? 0.9 : quality == .fair ? 0.6 : 0.3,
            beatIntervals: [0.83, 0.84, 0.82, 0.85],
            waveform: waveform
        )
    }
}
