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

internal struct ReadingCard_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<PulseReading> {
        let day: TimeInterval = 86_400
        return AppPreviewSnapshots(
            configurations: [
                .init(name: "Good Today", state: PreviewFixtures.reading()),
                .init(name: "Fair", state: PreviewFixtures.reading(bpm: 88, rmssd: 28, quality: .fair)),
                .init(name: "Poor", state: PreviewFixtures.reading(bpm: 64, rmssd: 19, quality: .poor)),
                .init(name: "HRV Unavailable", state: PreviewFixtures.reading(rmssd: nil, sdnn: nil, quality: .poor)),
                .init(name: "Yesterday", state: PreviewFixtures.reading(date: PreviewFixtures.now - day + 30_060)),
                .init(name: "Older", state: PreviewFixtures.reading(date: PreviewFixtures.now - 2 * day)),
                .init(name: "Three Digit BPM", state: PreviewFixtures.reading(bpm: 142, rmssd: 120)),
            ],
            configure: { reading in
                ReadingCard(reading: reading, now: PreviewFixtures.now, calendar: PreviewFixtures.calendar)
                    .frame(width: PreviewFixtures.componentWidth)
                    .padding()
                    .background(Color.background)
            }
        )
    }
}
