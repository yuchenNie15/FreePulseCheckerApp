import Foundation

public enum ReadingDateFormatter {
    /// "Today 9:41", "Yesterday 18:02", or "Oct 12" for older dates, in the calendar's time zone and locale.
    public static func string(for date: Date, now: Date, calendar: Calendar = .current) -> String {
        let locale = calendar.locale ?? .current
        let time = date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        )
        if calendar.isDate(date, inSameDayAs: now) { return "Today \(time)" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday \(time)"
        }
        return date.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).month(.abbreviated).day()
        )
    }
}
