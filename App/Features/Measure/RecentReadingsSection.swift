import DesignSystem
import Models
import SwiftUI

internal struct RecentReadingsSection: View {
    internal let readings: [PulseReading]
    /// Reference point for the "Today" / "Yesterday" labels on each card.
    internal let now: Date
    internal let onSeeAll: () -> Void
    internal let onSelect: (PulseReading.ID) -> Void

    internal var body: some View {
        VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
            header
                .padding(.top, 20)
            if readings.isEmpty {
                EmptyReadingsCard()
            } else {
                ForEach(readings) { reading in
                    Button {
                        onSelect(reading.id)
                    } label: {
                        ReadingCard(reading: reading, now: now)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Recent").microLabelStyle(.textSecondary)
            Spacer()
            if !readings.isEmpty {
                Button("See all", action: onSeeAll)
                    .font(.headline)
                    .foregroundStyle(Color.accentEnd)
            }
        }
        .padding(.horizontal, 4)
    }
}
