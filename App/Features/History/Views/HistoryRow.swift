import DesignSystem
import Models
import SwiftUI

internal struct HistoryRow: View {
    internal let reading: PulseReading
    /// Today and Yesterday rows show only the time; Earlier rows show a relative date.
    internal let day: HistorySection.Day
    internal let now: Date
    internal let calendar: Calendar

    internal init(reading: PulseReading, day: HistorySection.Day, now: Date, calendar: Calendar) {
        self.reading = reading
        self.day = day
        self.now = now
        self.calendar = calendar
    }

    internal var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(reading.quality.color)
                .frame(width: 10, height: 10)
                .accessibilityLabel(reading.quality.title)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(reading.bpm)").font(.rowNumeral).foregroundStyle(Color.textPrimary)
                Text("BPM").font(.subheadline.weight(.medium)).foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 8)
            HRVChip(rmssd: reading.rmssd)
            Spacer(minLength: 8)
            Text(timeText)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .monospacedDigit()
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(minHeight: 44)
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    private var timeText: String {
        switch day {
        case .today, .yesterday:
            reading.date.formatted(date: .omitted, time: .shortened)
        case .earlier:
            ReadingDateFormatter.string(for: reading.date, now: now, calendar: calendar)
        }
    }
}

internal struct HistoryRowPreviewState {
    internal var reading: PulseReading
    internal var day: HistorySection.Day

    internal init(reading: PulseReading, day: HistorySection.Day) {
        self.reading = reading
        self.day = day
    }
}

internal struct HistoryRow_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<HistoryRowPreviewState> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Good, with HRV, today", state: .init(reading: HistoryPreviewFixtures.todayGood, day: .today)),
                .init(name: "Fair, no HRV, today", state: .init(reading: HistoryPreviewFixtures.todayFairNoHRV, day: .today)),
                .init(name: "Poor, three-digit BPM, yesterday", state: .init(reading: HistoryPreviewFixtures.yesterdayPoor, day: .yesterday)),
                .init(name: "Fair, with HRV, earlier", state: .init(reading: HistoryPreviewFixtures.earlierFair, day: .earlier)),
                .init(
                    name: "Good, no HRV, three-digit BPM, earlier",
                    state: .init(reading: HistoryPreviewFixtures.earlierGoodThreeDigit, day: .earlier)
                ),
            ],
            configure: { state in
                HistoryRow(
                    reading: state.reading,
                    day: state.day,
                    now: HistoryPreviewFixtures.now,
                    calendar: HistoryPreviewFixtures.calendar
                )
                .padding(.horizontal)
                .frame(width: 358)
                .background(Color.surface)
            }
        )
    }
}
