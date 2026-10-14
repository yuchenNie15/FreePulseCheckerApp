import Foundation
import Models
import PulseEngine

/// Fixed readings for Measure previews and snapshots, dated relative to `now` (2026-10-14 09:41 UTC).
internal enum MeasurePreviewFixtures {
    internal static let now = Date(timeIntervalSince1970: 1_791_967_260)

    internal static let today = reading(1, hoursAgo: 0.2, bpm: 72, rmssd: 42, quality: .good)
    internal static let yesterday = reading(2, hoursAgo: 16, bpm: 68, rmssd: 38, quality: .fair)
    internal static let older = reading(3, hoursAgo: 50, bpm: 81, rmssd: nil, quality: .poor)
    internal static let lastWeek = reading(4, hoursAgo: 150, bpm: 64, rmssd: 45, quality: .good)
    internal static let threeDigitBPM = reading(5, hoursAgo: 1, bpm: 142, rmssd: 21, quality: .good)

    /// Newest first; one more than `MeasureFeature.recentCount`.
    internal static let all = [today, yesterday, older, lastWeek]

    private static func reading(_ id: Int, hoursAgo: Double, bpm: Int, rmssd: Double?, quality: SignalQuality) -> PulseReading {
        PulseReading(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            date: now.addingTimeInterval(-hoursAgo * 3600),
            bpm: bpm,
            rmssd: rmssd,
            sdnn: rmssd.map { $0 * 1.2 },
            quality: quality,
            qualityScore: quality == .good ? 0.86 : quality == .fair ? 0.55 : 0.3,
            beatIntervals: [],
            waveform: [],
            savedToHealth: quality != .poor
        )
    }
}
