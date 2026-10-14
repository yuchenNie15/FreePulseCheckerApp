import ComposableArchitecture
import DesignSystem
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
                    now: Date(),
                    onSeeAll: { store.send(.seeAllTapped) },
                    onSelect: { store.send(.readingTapped($0)) }
                )
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, 24)
        }
        .screenBackground()
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

#Preview {
    MeasureView(
        store: Store(initialState: MeasureFeature.State()) {
            MeasureFeature()
        }
    )
    .preferredColorScheme(.dark)
}
