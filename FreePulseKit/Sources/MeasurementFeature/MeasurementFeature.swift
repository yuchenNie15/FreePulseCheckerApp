import ComposableArchitecture
import PulseEngine
import SwiftUI

@Reducer
public struct MeasurementFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var analysis: PulseAnalysis.State

        public init(captureRate: Double) {
            analysis = PulseAnalysis.State(captureRate: captureRate)
        }
    }

    public enum Action: Equatable, Sendable {
        case analysis(PulseAnalysis.Action)
        case closeTapped
    }

    @Dependency(\.dismiss) private var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(\.analysis, action: \.analysis) { PulseAnalysis() }
        Reduce { _, action in
            switch action {
            case .closeTapped:
                return .run { _ in await dismiss() }
            case .analysis:
                return .none
            }
        }
    }
}

public struct MeasurementView: View {
    @Bindable private var store: StoreOf<MeasurementFeature>

    public init(store: StoreOf<MeasurementFeature>) {
        self.store = store
    }

    public var body: some View {
        Button("Close") { store.send(.closeTapped) }
    }
}
