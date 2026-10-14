import DesignSystem
import SwiftUI

internal struct HistorySectionHeader: View {
    internal let title: String

    internal init(title: String) {
        self.title = title
    }

    internal var body: some View {
        Text(title).microLabelStyle()
    }
}

internal struct HistorySectionHeader_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<HistorySection.Day> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Today", state: .today),
                .init(name: "Yesterday", state: .yesterday),
                .init(name: "Earlier", state: .earlier),
            ],
            configure: { day in
                HistorySectionHeader(title: HistorySection(day: day, readings: []).title)
                    .padding()
                    .background(Color.background)
            }
        )
    }
}
