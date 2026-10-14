import AppClients
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct HistoryFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        @Shared(.readings) public var readings
        @Shared(.selectedReadingID) public var selectedReadingID
        @Presents public var alert: AlertState<Action.Alert>?
        /// Reference point for grouping; refreshed from `date.now` each time the list appears.
        public var now: Date?
        public var calendar: Calendar

        public init(now: Date? = nil, calendar: Calendar = .autoupdatingCurrent) {
            self.now = now
            self.calendar = calendar
        }

        public var sections: [HistorySection] {
            HistorySection.group(Array(readings), now: now ?? .distantFuture, calendar: calendar)
        }

        public var selectedReading: PulseReading? {
            selectedReadingID.flatMap { readings[id: $0] }
        }

        /// The selection, or nil when it names a reading that no longer exists.
        public var presentedReadingID: PulseReading.ID? {
            selectedReading?.id
        }
    }

    public enum Action: Equatable, Sendable {
        case alert(PresentationAction<Alert>)
        case deleteSwiped(PulseReading.ID)
        case onAppear
        case rowTapped(PulseReading.ID)
        case selectionChanged(PulseReading.ID?)

        public enum Alert: Equatable, Sendable {
            case confirmDeletion(PulseReading.ID)
        }
    }

    @Dependency(\.calendar) private var calendar
    @Dependency(\.date.now) private var now
    @Dependency(\.readingStore) private var readingStore

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .alert(.presented(.confirmDeletion(id))):
                readingStore.delete(id)
                if state.selectedReadingID == id {
                    state.$selectedReadingID.withLock { $0 = nil }
                }
                return .none

            case .alert:
                return .none

            case let .deleteSwiped(id):
                guard state.readings[id: id] != nil else { return .none }
                state.alert = .deleteReading(id: id)
                return .none

            case .onAppear:
                state.now = now
                state.calendar = calendar
                if state.selectedReadingID != nil, state.selectedReading == nil {
                    state.$selectedReadingID.withLock { $0 = nil }
                }
                return .none

            case let .rowTapped(id):
                guard state.readings[id: id] != nil else { return .none }
                state.$selectedReadingID.withLock { $0 = id }
                return .none

            case let .selectionChanged(id):
                state.$selectedReadingID.withLock { $0 = id }
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

public struct HistorySection: Equatable, Identifiable, Sendable {
    public enum Day: Hashable, Sendable {
        case today
        case yesterday
        case earlier
    }

    public var day: Day
    public var readings: [PulseReading]

    public var id: Day { day }

    public var title: String {
        switch day {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .earlier: "Earlier"
        }
    }

    public init(day: Day, readings: [PulseReading]) {
        self.day = day
        self.readings = readings
    }

    /// Buckets readings by calendar day relative to `now`, keeping their order and omitting empty sections.
    public static func group(_ readings: [PulseReading], now: Date, calendar: Calendar) -> [HistorySection] {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)
        var buckets: [Day: [PulseReading]] = [:]
        for reading in readings {
            let day: Day
            if calendar.isDate(reading.date, inSameDayAs: now) {
                day = .today
            } else if let yesterday, calendar.isDate(reading.date, inSameDayAs: yesterday) {
                day = .yesterday
            } else {
                day = .earlier
            }
            buckets[day, default: []].append(reading)
        }
        return [Day.today, .yesterday, .earlier].compactMap { day in
            buckets[day].map { HistorySection(day: day, readings: $0) }
        }
    }
}

extension AlertState where Action == HistoryFeature.Action.Alert {
    fileprivate static func deleteReading(id: PulseReading.ID) -> Self {
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
