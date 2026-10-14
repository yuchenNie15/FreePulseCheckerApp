import AppClients
import ComposableArchitecture
import MeasurementFeature
import Models
import SwiftUI

@Reducer
public struct MeasureFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        @Shared(.readings) public var readings
        @Presents public var measurement: MeasurementFeature.State?

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case measurement(PresentationAction<MeasurementFeature.Action>)
        case seeAllTapped
    }

    @Dependency(\.appNavigator) private var appNavigator

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .seeAllTapped:
                appNavigator.showHistory()
                return .none
            case .measurement:
                return .none
            }
        }
        .ifLet(\.$measurement, action: \.measurement) { MeasurementFeature() }
    }
}

public struct MeasureView: View {
    @Bindable private var store: StoreOf<MeasureFeature>

    public init(store: StoreOf<MeasureFeature>) {
        self.store = store
    }

    public var body: some View {
        Text("Measure")
    }
}
