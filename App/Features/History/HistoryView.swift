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

#Preview("Populated") {
    @Shared(.readings) var readings = IdentifiedArray(uniqueElements: PulseReading.previewReadings())
    return HistoryView(store: Store(initialState: HistoryFeature.State()) { HistoryFeature() })
}

#Preview("Empty") {
    @Shared(.readings) var readings = []
    return HistoryView(store: Store(initialState: HistoryFeature.State()) { HistoryFeature() })
}
