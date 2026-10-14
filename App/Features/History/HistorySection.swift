import Foundation
import Models

internal struct HistorySection: Equatable, Identifiable, Sendable {
    internal enum Day: Hashable, Sendable {
        case today
        case yesterday
        case earlier
    }

    internal var day: Day
    internal var readings: [PulseReading]

    internal var id: Day { day }

    internal var title: String {
        switch day {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .earlier: "Earlier"
        }
    }

    internal init(day: Day, readings: [PulseReading]) {
        self.day = day
        self.readings = readings
    }

    /// Buckets readings by calendar day relative to `now`, keeping their order and omitting empty sections.
    internal static func group(_ readings: [PulseReading], now: Date, calendar: Calendar) -> [HistorySection] {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)
        var buckets: [Day: [PulseReading]] = [:]
        for reading in readings {
            let day: Day
            if calendar.isDate(reading.date, inSameDayAs: now) {
                day = .today
            } else if let yesterday, calendar.isDate(reading.date, inSameDayAs: yesterday) {
                day = .yesterday
            } else {
                day = .earlier
            }
            buckets[day, default: []].append(reading)
        }
        return [Day.today, .yesterday, .earlier].compactMap { day in
            buckets[day].map { HistorySection(day: day, readings: $0) }
        }
    }
}
