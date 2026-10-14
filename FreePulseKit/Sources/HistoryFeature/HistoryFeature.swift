import ComposableArchitecture
import Models
import SwiftUI

@Reducer
public struct HistoryFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        @Shared(.readings) public var readings

        public init() {}
    }

    public enum Action: Equatable, Sendable {}

    public init() {}

    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

public struct HistoryView: View {
    private let store: StoreOf<HistoryFeature>

    public init(store: StoreOf<HistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        Text("History")
    }
}
