import Foundation
import Models
import PulseEngine

/// Fixed readings for History previews and snapshots, relative to 2026-10-14 09:41 UTC.
internal enum HistoryPreviewFixtures {
    internal static let now = Date(timeIntervalSince1970: 1_791_967_260)

    internal static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// 09:21 today.
    internal static let todayGood = reading(1, minutesAgo: 20, bpm: 72, quality: .good, hrv: (42, 51))

    /// 07:05 today.
    internal static let todayFairNoHRV = reading(2, minutesAgo: 156, bpm: 64, quality: .fair, hrv: nil, savedToHealth: false)

    /// 21:15 yesterday.
    internal static let yesterdayPoor = reading(3, minutesAgo: 746, bpm: 104, quality: .poor, hrv: (29, 33))

    /// 06:30 yesterday.
    internal static let yesterdayGood = reading(4, minutesAgo: 1_631, bpm: 58, quality: .good, hrv: (55, 61))

    /// 18:00 on Oct 12.
    internal static let earlierFair = reading(5, minutesAgo: 2_381, bpm: 81, quality: .fair, hrv: (31, 38))

    /// 08:00 on Oct 9.
    internal static let earlierGoodThreeDigit = reading(6, minutesAgo: 7_301, bpm: 112, quality: .good, hrv: nil)

    internal static let todayOnly = [todayGood, todayFairNoHRV]

    internal static let todayAndYesterday = todayOnly + [yesterdayPoor, yesterdayGood]

    internal static let allSections = todayAndYesterday + [earlierFair, earlierGoodThreeDigit]

    /// Twelve readings spread across this morning, enough to scroll.
    internal static let manyToday = (0..<12).map { index in
        reading(
            100 + index,
            minutesAgo: 10 + index * 45,
            bpm: 60 + index * 3,
            quality: [SignalQuality.good, .fair, .poor][index % 3],
            hrv: index.isMultiple(of: 4) ? nil : (Double(30 + index), Double(40 + index))
        )
    }

    internal static func reading(
        _ number: Int,
        minutesAgo: Int,
        bpm: Int,
        quality: SignalQuality,
        hrv: (rmssd: Double, sdnn: Double)?,
        savedToHealth: Bool = true,
        hasWaveform: Bool = true
    ) -> PulseReading {
        PulseReading(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!,
            date: now.addingTimeInterval(-Double(minutesAgo) * 60),
            bpm: bpm,
            rmssd: hrv?.rmssd,
            sdnn: hrv?.sdnn,
            quality: quality,
            qualityScore: quality == .good ? 0.86 : quality == .fair ? 0.55 : 0.3,
            beatIntervals: [],
            waveform: hasWaveform ? waveform : [],
            savedToHealth: savedToHealth
        )
    }

    private static let waveform = (0..<100).map { index -> Double in
        let phase = Double(index).truncatingRemainder(dividingBy: 20) / 20
        return exp(-pow((phase - 0.2) / 0.06, 2)) + 0.35 * exp(-pow((phase - 0.5) / 0.08, 2))
    }
}
