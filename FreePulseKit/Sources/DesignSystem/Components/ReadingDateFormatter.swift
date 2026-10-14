import Foundation

public enum ReadingDateFormatter {
    /// "Today 9:41", "Yesterday 18:02", or "Oct 12" for older dates.
    public static func string(for date: Date, now: Date, calendar: Calendar = .current) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDate(date, inSameDayAs: now) { return "Today \(time)" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday \(time)"
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
