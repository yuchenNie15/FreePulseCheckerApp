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
