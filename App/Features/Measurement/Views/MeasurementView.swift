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

internal struct MeasurementView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<MeasurementFeature.State> {
        typealias Fixtures = MeasurementFlowPreviewFixtures
        let measuring = Fixtures.state(phase: .measuring, snapshot: Fixtures.measuringSnapshot, remainingSeconds: 34)
        return AppPreviewSnapshots(
            configurations: [
                .init(name: "Preparing", state: Fixtures.state(phase: .preparing)),
                .init(name: "Waiting For Finger", state: Fixtures.state(phase: .waitingForFinger)),
                .init(
                    name: "Calibrating",
                    state: Fixtures.state(phase: .calibrating, snapshot: PulseSnapshot(fingerState: .present))
                ),
                .init(name: "Measuring", state: measuring),
                .init(
                    name: "Paused",
                    state: Fixtures.state(phase: .paused, snapshot: PulseSnapshot(fingerState: .absent), remainingSeconds: 34)
                ),
                .init(name: "Result", state: Fixtures.state(phase: .result(Fixtures.reading))),
                .init(name: "Failed", state: Fixtures.state(phase: .failed(.unreliable))),
                .init(
                    name: "Stop Measuring Alert",
                    state: Fixtures.state(
                        phase: .measuring,
                        snapshot: Fixtures.measuringSnapshot,
                        remainingSeconds: 34,
                        alert: .stopMeasuring
                    )
                ),
            ],
            configure: { state in
                MeasurementView(store: Store(initialState: state) { EmptyReducer() })
            }
        )
    }
}
