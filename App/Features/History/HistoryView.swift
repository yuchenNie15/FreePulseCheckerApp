import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

internal struct HistoryView: View {
    @Bindable private var store: StoreOf<HistoryFeature>

    internal init(store: StoreOf<HistoryFeature>) {
        self.store = store
    }

    internal var body: some View {
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
            HistoryList(
                sections: store.sections,
                now: store.now ?? Date(),
                calendar: store.calendar,
                onRowTapped: { store.send(.rowTapped($0)) },
                onDeleteSwiped: { store.send(.deleteSwiped($0)) }
            )
        }
    }
}

internal struct HistoryViewPreviewState {
    internal var readings: [PulseReading]
    internal var selectedReadingID: PulseReading.ID?
    internal var deleteAlertReadingID: PulseReading.ID?

    internal init(
        readings: [PulseReading],
        selectedReadingID: PulseReading.ID? = nil,
        deleteAlertReadingID: PulseReading.ID? = nil
    ) {
        self.readings = readings
        self.selectedReadingID = selectedReadingID
        self.deleteAlertReadingID = deleteAlertReadingID
    }
}

internal struct HistoryView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<HistoryViewPreviewState> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Empty", state: .init(readings: [])),
                .init(name: "Today only", state: .init(readings: HistoryPreviewFixtures.todayOnly)),
                .init(name: "Today and Yesterday", state: .init(readings: HistoryPreviewFixtures.todayAndYesterday)),
                .init(name: "All sections", state: .init(readings: HistoryPreviewFixtures.allSections)),
                .init(
                    name: "Delete alert",
                    state: .init(
                        readings: HistoryPreviewFixtures.allSections,
                        deleteAlertReadingID: HistoryPreviewFixtures.todayGood.id
                    )
                ),
                .init(
                    name: "Reading selected",
                    state: .init(
                        readings: HistoryPreviewFixtures.allSections,
                        selectedReadingID: HistoryPreviewFixtures.todayGood.id
                    )
                ),
            ],
            configure: { state in
                HistoryView(
                    store: Store(
                        initialState: HistoryFeature.State(
                            readings: Shared(value: IdentifiedArray(uniqueElements: state.readings)),
                            selectedReadingID: Shared(value: state.selectedReadingID),
                            alert: state.deleteAlertReadingID.map { .deleteReading(id: $0) },
                            now: HistoryPreviewFixtures.now,
                            calendar: HistoryPreviewFixtures.calendar
                        )
                    ) {
                        EmptyReducer()
                    }
                )
            }
        )
    }
}
