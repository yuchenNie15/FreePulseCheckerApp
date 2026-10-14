import DesignSystem
import Models
import SwiftUI

internal struct HistoryList: View {
    internal let sections: [HistorySection]
    /// Reference point for the "Earlier" rows' relative dates.
    internal let now: Date
    internal let calendar: Calendar
    internal let onRowTapped: (PulseReading.ID) -> Void
    internal let onDeleteSwiped: (PulseReading.ID) -> Void

    internal init(
        sections: [HistorySection],
        now: Date,
        calendar: Calendar,
        onRowTapped: @escaping (PulseReading.ID) -> Void,
        onDeleteSwiped: @escaping (PulseReading.ID) -> Void
    ) {
        self.sections = sections
        self.now = now
        self.calendar = calendar
        self.onRowTapped = onRowTapped
        self.onDeleteSwiped = onDeleteSwiped
    }

    internal var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.readings) { reading in
                        Button {
                            onRowTapped(reading.id)
                        } label: {
                            HistoryRow(reading: reading, day: section.day, now: now, calendar: calendar)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.surface)
                        .listRowSeparatorTint(Color.separator)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                onDeleteSwiped(reading.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(Color.destructive)
                        }
                    }
                } header: {
                    HistorySectionHeader(title: section.title)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(20)
        .scrollContentBackground(.hidden)
    }
}

internal struct HistoryList_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<[PulseReading]> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "One section", state: HistoryPreviewFixtures.todayOnly),
                .init(name: "Two sections", state: HistoryPreviewFixtures.todayAndYesterday),
                .init(name: "Three sections", state: HistoryPreviewFixtures.allSections),
                .init(name: "Many rows in one section", state: HistoryPreviewFixtures.manyToday),
            ],
            configure: { readings in
                HistoryList(
                    sections: HistorySection.group(
                        readings,
                        now: HistoryPreviewFixtures.now,
                        calendar: HistoryPreviewFixtures.calendar
                    ),
                    now: HistoryPreviewFixtures.now,
                    calendar: HistoryPreviewFixtures.calendar,
                    onRowTapped: { _ in },
                    onDeleteSwiped: { _ in }
                )
                .frame(width: 390, height: 760)
                .background(Color.background)
            }
        )
    }
}
