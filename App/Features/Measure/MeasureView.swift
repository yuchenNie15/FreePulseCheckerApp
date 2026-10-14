import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

internal struct MeasureView: View {
    @Bindable private var store: StoreOf<MeasureFeature>

    internal init(store: StoreOf<MeasureFeature>) {
        self.store = store
    }

    internal var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
                Text("Free Pulse Check")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                if let warning = store.healthWarning {
                    HealthWarningBanner(message: warning) {
                        store.send(.healthWarningDismissed)
                    }
                }
                MeasureStartCard { store.send(.startTapped) }
                RecentReadingsSection(
                    readings: store.recentReadings,
                    now: store.now,
                    onSeeAll: { store.send(.seeAllTapped) },
                    onSelect: { store.send(.readingTapped($0)) }
                )
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .onAppear { store.send(.onAppear) }
        .fullScreenCover(item: $store.scope(\.measurement, action: \.measurement)) { measurementStore in
            MeasurementView(store: measurementStore)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.isCameraDeniedPresented },
                set: { if !$0 { store.send(.cameraDeniedDismissed) } }
            )
        ) {
            CameraDeniedView {
                store.send(.openSettingsTapped)
            } onDismiss: {
                store.send(.cameraDeniedDismissed)
            }
        }
    }
}

internal struct MeasureView_Previews: PreviewProvider {
    internal struct State {
        internal var readings: [PulseReading] = []
        internal var healthWarning: String?
    }

    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<State> {
        let warning = "Saved on this iPhone. Apple Health access is off."
        return AppPreviewSnapshots(
            configurations: [
                .init(name: "Empty", state: State()),
                .init(name: "One reading", state: State(readings: [MeasurePreviewFixtures.today])),
                .init(name: "Four readings, three shown", state: State(readings: MeasurePreviewFixtures.all)),
                .init(name: "Health warning, empty", state: State(healthWarning: warning)),
                .init(name: "Health warning, with readings", state: State(readings: MeasurePreviewFixtures.all, healthWarning: warning)),
            ],
            configure: { state in
                MeasureView(
                    store: Store(
                        initialState: MeasureFeature.State(
                            readings: Shared(value: IdentifiedArray(uniqueElements: state.readings)),
                            healthWarning: Shared(value: state.healthWarning),
                            now: MeasurePreviewFixtures.now
                        )
                    ) { EmptyReducer() }
                )
            }
        )
    }
}
