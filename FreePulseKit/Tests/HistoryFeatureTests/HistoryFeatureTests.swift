import AppClients
import ComposableArchitecture
import Foundation
import Models
import Testing
@testable import HistoryFeature

@MainActor
@Suite struct HistoryFeatureTests {
    @Test func onAppearGroupsReadingsIntoTodayYesterdayAndEarlier() async {
        let todayMorning = reading(at: "2026-10-14T08:00:00Z")
        let justAfterMidnight = reading(at: "2026-10-14T00:01:00Z")
        let yesterdayLate = reading(at: "2026-10-13T23:59:00Z")
        let yesterdayEarly = reading(at: "2026-10-13T00:00:00Z")
        let twoDaysAgo = reading(at: "2026-10-12T23:59:00Z")
        let lastMonth = reading(at: "2026-09-01T12:00:00Z")
        let store = makeStore(readings: [todayMorning, justAfterMidnight, yesterdayLate, yesterdayEarly, twoDaysAgo, lastMonth])

        await store.send(.onAppear) {
            $0.now = now
            $0.calendar = utcCalendar
        }

        #expect(
            store.state.sections == [
                HistorySection(day: .today, readings: [todayMorning, justAfterMidnight]),
                HistorySection(day: .yesterday, readings: [yesterdayLate, yesterdayEarly]),
                HistorySection(day: .earlier, readings: [twoDaysAgo, lastMonth]),
            ]
        )
        #expect(store.state.sections.map(\.title) == ["Today", "Yesterday", "Earlier"])
    }

    @Test func groupingOmitsEmptySections() {
        let older = reading(at: "2026-10-01T10:00:00Z")

        #expect(HistorySection.group([older], now: now, calendar: utcCalendar) == [HistorySection(day: .earlier, readings: [older])])
        #expect(HistorySection.group([], now: now, calendar: utcCalendar).isEmpty)
    }

    @Test func rowTappedSelectsReading() async {
        let first = reading(at: "2026-10-14T08:00:00Z")
        let store = makeStore(readings: [first])

        await store.send(.rowTapped(first.id)) {
            $0.$selectedReadingID.withLock { $0 = first.id }
        }
        #expect(store.state.selectedReading == first)
        #expect(store.state.presentedReadingID == first.id)
    }

    @Test func rowTappedWithUnknownIDDoesNothing() async {
        let store = makeStore(readings: [reading(at: "2026-10-14T08:00:00Z")])

        await store.send(.rowTapped(UUID()))
    }

    @Test func externalSelectionOfUnknownIDPresentsNothingAndClearsOnAppear() async {
        let unknown = UUID()
        let store = makeStore(readings: [reading(at: "2026-10-14T08:00:00Z")], selected: unknown)

        #expect(store.state.presentedReadingID == nil)
        await store.send(.onAppear) {
            $0.now = now
            $0.$selectedReadingID.withLock { $0 = nil }
        }
    }

    @Test func externalSelectionOfKnownIDPresentsDetail() async {
        let first = reading(at: "2026-10-14T08:00:00Z")
        let store = makeStore(readings: [first], selected: first.id)

        #expect(store.state.presentedReadingID == first.id)
        await store.send(.onAppear) {
            $0.now = now
        }
    }

    @Test func dismissingDetailClearsSelection() async {
        let first = reading(at: "2026-10-14T08:00:00Z")
        let store = makeStore(readings: [first])

        await store.send(.rowTapped(first.id)) {
            $0.$selectedReadingID.withLock { $0 = first.id }
        }
        await store.send(.selectionChanged(nil)) {
            $0.$selectedReadingID.withLock { $0 = nil }
        }
    }

    @Test func confirmingDeleteDeletesThroughReadingStore() async {
        let first = reading(at: "2026-10-14T08:00:00Z")
        let second = reading(at: "2026-10-13T08:00:00Z")
        let deleted = LockIsolated<[PulseReading.ID]>([])
        let store = makeStore(readings: [first, second], deleted: deleted)

        await store.send(.deleteSwiped(first.id)) {
            $0.alert = deleteAlert(id: first.id)
        }
        await store.send(.alert(.presented(.confirmDeletion(first.id)))) {
            $0.alert = nil
        }
        #expect(deleted.value == [first.id])
    }

    @Test func cancellingDeleteKeepsReading() async {
        let first = reading(at: "2026-10-14T08:00:00Z")
        let deleted = LockIsolated<[PulseReading.ID]>([])
        let store = makeStore(readings: [first], deleted: deleted)

        await store.send(.deleteSwiped(first.id)) {
            $0.alert = deleteAlert(id: first.id)
        }
        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }
        #expect(deleted.value.isEmpty)
        #expect(store.state.readings == [first])
    }

    @Test func deletingSelectedReadingClearsSelection() async {
        let first = reading(at: "2026-10-14T08:00:00Z")
        let deleted = LockIsolated<[PulseReading.ID]>([])
        let store = makeStore(readings: [first], selected: first.id, deleted: deleted)

        await store.send(.deleteSwiped(first.id)) {
            $0.alert = deleteAlert(id: first.id)
        }
        await store.send(.alert(.presented(.confirmDeletion(first.id)))) {
            $0.alert = nil
            $0.$selectedReadingID.withLock { $0 = nil }
        }
        #expect(deleted.value == [first.id])
    }

    @Test func deleteSwipedWithUnknownIDDoesNothing() async {
        let store = makeStore(readings: [reading(at: "2026-10-14T08:00:00Z")])

        await store.send(.deleteSwiped(UUID()))
    }
}

private let now = date("2026-10-14T09:41:00Z")

private let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

@MainActor
private func makeStore(
    readings seed: [PulseReading],
    selected: PulseReading.ID? = nil,
    deleted: LockIsolated<[PulseReading.ID]> = LockIsolated([])
) -> TestStoreOf<HistoryFeature> {
    @Shared(.readings) var readings
    @Shared(.selectedReadingID) var selectedReadingID
    $readings.withLock { $0 = IdentifiedArray(uniqueElements: seed) }
    $selectedReadingID.withLock { $0 = selected }
    return TestStore(initialState: HistoryFeature.State(calendar: utcCalendar)) {
        HistoryFeature()
    } withDependencies: {
        $0.date.now = now
        $0.calendar = utcCalendar
        $0.readingStore.delete = { id in deleted.withValue { $0.append(id) } }
    }
}

private func deleteAlert(id: PulseReading.ID) -> AlertState<HistoryFeature.Action.Alert> {
    AlertState {
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

private func reading(at iso8601: String) -> PulseReading {
    PulseReading(
        id: UUID(),
        date: date(iso8601),
        bpm: 70,
        rmssd: 40,
        sdnn: 50,
        quality: .good,
        qualityScore: 0.9,
        beatIntervals: [],
        waveform: [],
        savedToHealth: true
    )
}

private func date(_ iso8601: String) -> Date {
    try! Date(iso8601, strategy: .iso8601)
}
