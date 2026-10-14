import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct HistoryView: View {
    @Bindable private var store: StoreOf<HistoryFeature>

    public init(store: StoreOf<HistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            content
                .screenBackground()
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationDestination(item: $store.presentedReadingID.sending(\.selectionChanged)) { _ in
                    if let reading = store.selectedReading {
                        ReadingDetailView(reading: reading)
                    }
                }
                .alert($store.scope(\.alert, action: \.alert))
                .onAppear { store.send(.onAppear) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.readings.isEmpty {
            EmptyHistoryView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(store.sections) { section in
                    Section {
                        ForEach(section.readings) { reading in
                            Button {
                                store.send(.rowTapped(reading.id))
                            } label: {
                                HistoryRow(reading: reading, timeText: timeText(for: reading, in: section.day))
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.surface)
                            .listRowSeparatorTint(Color.separator)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    store.send(.deleteSwiped(reading.id))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(Color.destructive)
                            }
                        }
                    } header: {
                        Text(section.title).microLabelStyle()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(20)
            .scrollContentBackground(.hidden)
        }
    }

    private func timeText(for reading: PulseReading, in day: HistorySection.Day) -> String {
        switch day {
        case .today, .yesterday:
            reading.date.formatted(date: .omitted, time: .shortened)
        case .earlier:
            ReadingDateFormatter.string(for: reading.date, now: store.now ?? Date(), calendar: store.calendar)
        }
    }
}

private struct HistoryRow: View {
    fileprivate let reading: PulseReading
    fileprivate let timeText: String

    fileprivate var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(reading.quality.color)
                .frame(width: 10, height: 10)
                .accessibilityLabel("\(reading.quality.title) quality")
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
}

private struct ReadingDetailView: View {
    fileprivate let reading: PulseReading

    fileprivate var body: some View {
        ScrollView {
            VStack(spacing: Metrics.cardSpacing) {
                ReadingSummaryView(reading: reading)
                VStack(alignment: .leading, spacing: 14) {
                    Text(reading.date.formatted(date: .complete, time: .shortened))
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                    Divider().overlay(Color.separator)
                    Label {
                        Text(reading.savedToHealth ? "Saved to Apple Health" : "Not in Apple Health")
                            .foregroundStyle(Color.textPrimary)
                    } icon: {
                        Image(systemName: reading.savedToHealth ? "heart.fill" : "heart.slash")
                            .foregroundStyle(reading.savedToHealth ? Color.accentStart : Color.textTertiary)
                    }
                    .font(.body)
                }
                .card()
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

private struct EmptyHistoryView: View {
    fileprivate var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.fill")
                .font(.system(size: 34))
                .foregroundStyle(LinearGradient.accent)
                .frame(width: 76, height: 76)
                .background(Color.accentTint, in: .circle)
            Text("No readings yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textPrimary)
            Text("Your measurements will appear here.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(Metrics.screenMargin)
    }
}

#Preview("Populated") {
    @Shared(.readings) var readings = IdentifiedArray(uniqueElements: PulseReading.previewReadings())
    return HistoryView(store: Store(initialState: HistoryFeature.State()) { HistoryFeature() })
}

#Preview("Empty") {
    @Shared(.readings) var readings = []
    return HistoryView(store: Store(initialState: HistoryFeature.State()) { HistoryFeature() })
}
