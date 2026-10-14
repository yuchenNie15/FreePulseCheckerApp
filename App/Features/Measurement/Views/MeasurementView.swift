import ComposableArchitecture
import DesignSystem
import Models
import PulseEngine
import SwiftUI

internal struct MeasurementView: View {
    @Bindable private var store: StoreOf<MeasurementFeature>
    @Environment(\.scenePhase) private var scenePhase

    internal init(store: StoreOf<MeasurementFeature>) {
        self.store = store
    }

    internal var body: some View {
        VStack(spacing: 0) {
            MeasurementHeader(phase: store.phase) {
                store.send(.closeTapped)
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .screenBackground()
        .preferredColorScheme(.dark)
        .task { await store.send(.task).finish() }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
        .alert($store.scope(\.alert, action: \.alert))
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .preparing, .waitingForFinger:
            WaitingForFingerView(fingerState: store.analysis.snapshot.fingerState)
        case .calibrating, .measuring, .paused:
            LiveMeasurementView(
                phase: store.phase,
                snapshot: store.analysis.snapshot,
                remainingSeconds: store.remainingSeconds
            )
        case let .result(reading):
            MeasurementResultView(reading: reading, saveToHealth: $store.saveToHealth) {
                store.send(.saveTapped)
            } onDiscard: {
                store.send(.discardTapped)
            }
        case let .failed(reason):
            MeasurementFailedView(reason: reason) {
                store.send(.tryAgainTapped)
            } onClose: {
                store.send(.closeTapped)
            }
        }
    }
}

#Preview("Measuring") {
    MeasurementView(
        store: Store(initialState: MeasurementFeature.State(captureRate: 60)) {
            MeasurementFeature()
        }
    )
}
