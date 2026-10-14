import DesignSystem
import Models
import SwiftUI

internal struct ReadingDetailView: View {
    internal let reading: PulseReading

    internal init(reading: PulseReading) {
        self.reading = reading
    }

    internal var body: some View {
        ScrollView {
            VStack(spacing: Metrics.cardSpacing) {
                ReadingSummaryView(reading: reading)
                ReadingHealthStatusCard(date: reading.date, savedToHealth: reading.savedToHealth)
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

internal struct ReadingDetailView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<PulseReading> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Good, with HRV, saved to Health", state: HistoryPreviewFixtures.todayGood),
                .init(name: "Fair, no HRV, not saved to Health", state: HistoryPreviewFixtures.todayFairNoHRV),
                .init(name: "Poor, with HRV, saved to Health", state: HistoryPreviewFixtures.yesterdayPoor),
                .init(
                    name: "No waveform",
                    state: HistoryPreviewFixtures.reading(7, minutesAgo: 20, bpm: 72, quality: .good, hrv: (42, 51), hasWaveform: false)
                ),
            ],
            configure: { reading in
                NavigationStack {
                    ReadingDetailView(reading: reading)
                }
            }
        )
    }
}
