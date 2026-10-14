import AppClients
import ComposableArchitecture
import Foundation
import Models

@Reducer
internal struct HistoryFeature: Sendable {
    @ObservableState
    internal struct State: Equatable, Sendable {
        @Shared(.readings) internal var readings
        @Shared(.selectedReadingID) internal var selectedReadingID
        @Presents internal var alert: AlertState<Action.Alert>?
        /// Reference point for grouping; refreshed from `date.now` each time the list appears.
        internal var now: Date?
        internal var calendar: Calendar

        internal init(
            readings: Shared<IdentifiedArrayOf<PulseReading>> = Shared(.readings),
            selectedReadingID: Shared<PulseReading.ID?> = Shared(.selectedReadingID),
            alert: AlertState<Action.Alert>? = nil,
            now: Date? = nil,
            calendar: Calendar = .autoupdatingCurrent
        ) {
            _readings = readings
            _selectedReadingID = selectedReadingID
            self.alert = alert
            self.now = now
            self.calendar = calendar
        }

        internal var sections: [HistorySection] {
            HistorySection.group(Array(readings), now: now ?? .distantFuture, calendar: calendar)
        }

        internal var selectedReading: PulseReading? {
            selectedReadingID.flatMap { readings[id: $0] }
        }

        /// The selection, or nil when it names a reading that no longer exists.
        internal var presentedReadingID: PulseReading.ID? {
            selectedReading?.id
        }
    }

    internal enum Action: Equatable, Sendable {
        case alert(PresentationAction<Alert>)
        case deleteSwiped(PulseReading.ID)
        case onAppear
        case rowTapped(PulseReading.ID)
        case selectionChanged(PulseReading.ID?)

        internal enum Alert: Equatable, Sendable {
            case confirmDeletion(PulseReading.ID)
        }
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.date.now) private var now
    @Dependency(\.log) private var log
    @Dependency(\.readingStore) private var readingStore

    internal init() {}

    internal var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .alert(.presented(.confirmDeletion(id))):
                readingStore.delete(id)
                if state.selectedReadingID == id {
                    state.$selectedReadingID.withLock { $0 = nil }
                }
                return log.info(.history, "Deleted reading \(id)")

            case .alert:
                return .none

            case let .deleteSwiped(id):
                guard state.readings[id: id] != nil else { return .none }
                state.alert = .deleteReading(id: id)
                return log.debug(.history, "Delete requested for \(id)")

            case .onAppear:
                state.now = now
                state.calendar = calendar
                let logAppear: Effect<Action> = log.debug(.history, "Appeared with \(state.readings.count) readings")
                if let staleID = state.selectedReadingID, state.selectedReading == nil {
                    state.$selectedReadingID.withLock { $0 = nil }
                    return .merge(logAppear, log.info(.history, "Cleared selection of missing reading \(staleID)"))
                }
                return logAppear

            case let .rowTapped(id):
                guard state.readings[id: id] != nil else { return .none }
                state.$selectedReadingID.withLock { $0 = id }
                return log.debug(.history, "Opened reading \(id)")

            case let .selectionChanged(id):
                state.$selectedReadingID.withLock { $0 = id }
                return log.debug(.history, "Selection changed to \(id.map { "\($0)" } ?? "none")")
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == HistoryFeature.Action.Alert {
    internal static func deleteReading(id: PulseReading.ID) -> Self {
        Self {
            TextState("Delete this reading?")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion(id)) {
                TextState("Delete")
            }
            ButtonState(role: .cancel) {
                TextState("Cancel")
            }
        } message: {
            TextState("It's removed from this app. Apple Health keeps its copy.")
        }
    }
}
