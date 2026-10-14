import Models
import SwiftUI

/// A saved reading as a tappable card: BPM, RMSSD chip, quality and date.
public struct ReadingCard: View {
    private let reading: PulseReading
    private let now: Date
    private let calendar: Calendar

    public init(reading: PulseReading, now: Date = Date()) {
        self.init(reading: reading, now: now, calendar: .current)
    }

    internal init(reading: PulseReading, now: Date, calendar: Calendar) {
        self.reading = reading
        self.now = now
        self.calendar = calendar
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(reading.bpm)").font(.cardNumeral).foregroundStyle(Color.textPrimary)
                    Text("BPM").font(.headline).foregroundStyle(Color.textSecondary)
                }
                HRVChip(rmssd: reading.rmssd)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 14) {
                QualityBadge(reading.quality)
                Text(ReadingDateFormatter.string(for: reading.date, now: now, calendar: calendar))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textTertiary)
                .padding(.leading, 8)
        }
        .card(padding: 18)
        .accessibilityElement(children: .combine)
    }
}
