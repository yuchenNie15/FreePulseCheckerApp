import DesignSystem
import SwiftUI

internal struct ReadingHealthStatusCard: View {
    internal let date: Date
    internal let savedToHealth: Bool

    internal init(date: Date, savedToHealth: Bool) {
        self.date = date
        self.savedToHealth = savedToHealth
    }

    internal var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(date.formatted(date: .complete, time: .shortened))
                .font(.body)
                .foregroundStyle(Color.textPrimary)
            Divider().overlay(Color.separator)
            Label {
                Text(savedToHealth ? "Saved to Apple Health" : "Not in Apple Health")
                    .foregroundStyle(Color.textPrimary)
            } icon: {
                Image(systemName: savedToHealth ? "heart.fill" : "heart.slash")
                    .foregroundStyle(savedToHealth ? Color.accentStart : Color.textTertiary)
            }
            .font(.body)
        }
        .card()
    }
}

internal struct ReadingHealthStatusCard_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Bool> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Saved to Health", state: true),
                .init(name: "Not saved to Health", state: false),
            ],
            configure: { savedToHealth in
                ReadingHealthStatusCard(date: HistoryPreviewFixtures.todayGood.date, savedToHealth: savedToHealth)
                    .frame(width: 358)
                    .padding()
                    .background(Color.background)
            }
        )
    }
}
