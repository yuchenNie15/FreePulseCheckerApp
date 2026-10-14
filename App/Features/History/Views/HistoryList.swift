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
