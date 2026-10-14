import AppClients
import ComposableArchitecture
import Foundation
import Models
import PulseEngine
import PulseSourceClient
import Testing
import UIKit
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasureFeatureTests {
    @Test internal func startWithCameraAuthorizedPresentsTheMeasurement() async {
        let store = makeStore {
            $0.cameraPermission.status = { .authorized }
        }

        await store.send(.startTapped) {
            $0.measurement = MeasurementFeature.State(captureRate: 30)
        }
    }

    @Test internal func startWithCameraUndeterminedPresentsOnceGranted() async {
        let store = makeStore {
            $0.cameraPermission.status = { .notDetermined }
            $0.cameraPermission.request = { true }
        }

        await store.send(.startTapped)
        await store.receive(.cameraPermissionResponse(granted: true)) {
            $0.measurement = MeasurementFeature.State(captureRate: 30)
        }
    }

    @Test internal func startWithCameraUndeterminedShowsDeniedWhenRefused() async {
        let store = makeStore {
            $0.cameraPermission.status = { .notDetermined }
            $0.cameraPermission.request = { false }
        }

        await store.send(.startTapped)
        await store.receive(.cameraPermissionResponse(granted: false)) {
            $0.isCameraDeniedPresented = true
        }
    }

    @Test internal func startWithCameraDeniedShowsDeniedUntilNotNow() async {
        let store = makeStore {
            $0.cameraPermission.status = { .denied }
        }

        await store.send(.startTapped) {
            $0.isCameraDeniedPresented = true
        }
        await store.send(.cameraDeniedDismissed) {
            $0.isCameraDeniedPresented = false
        }
    }

    @Test internal func startWithCameraDeniedLogsTheTapAndTheDeniedSheet() async {
        let entries = LockIsolated<[LogEntry]>([])
        let store = makeStore {
            $0.cameraPermission.status = { .denied }
            $0.log.write = { entry in entries.withValue { $0.append(entry) } }
        }

        await store.send(.startTapped) {
            $0.isCameraDeniedPresented = true
        }
        await store.finish()

        #expect(Set(entries.value.map(\.message)) == [
            "Start tapped, camera denied",
            "Camera denied, showing the denied sheet",
        ])
    }

    @Test internal func openSettingsOpensTheAppSettingsAndDismisses() async {
        let opened = LockIsolated<[URL]>([])
        var initialState = MeasureFeature.State()
        initialState.isCameraDeniedPresented = true
        let store = makeStore(initialState) {
            $0.openURL = OpenURLEffect { url in
                opened.withValue { $0.append(url) }
                return true
            }
        }

        await store.send(.openSettingsTapped) {
            $0.isCameraDeniedPresented = false
        }
        await store.finish()

        #expect(opened.value == [URL(string: UIApplication.openSettingsURLString)!])
    }

    @Test internal func seeAllShowsHistory() async {
        let shown = LockIsolated(0)
        let store = makeStore {
            $0.appNavigator.showHistory = { shown.withValue { $0 += 1 } }
        }

        await store.send(.seeAllTapped)
        await store.finish()

        #expect(shown.value == 1)
    }

    @Test internal func tappingARecentReadingShowsIt() async {
        let shown = LockIsolated<[PulseReading.ID]>([])
        let store = makeStore {
            $0.appNavigator.showReading = { id in shown.withValue { $0.append(id) } }
        }

        await store.send(.readingTapped(UUID(3)))
        await store.finish()

        #expect(shown.value == [UUID(3)])
    }

    @Test internal func recentReadingsAreTheNewestThree() {
        let readings = PulseReading.previewReadings(now: Date(timeIntervalSince1970: 1_800_000_000))
        let state = MeasureFeature.State(readings: Shared(value: IdentifiedArray(uniqueElements: readings)))

        #expect(state.recentReadings == Array(readings.prefix(3)))
    }

    @Test internal func noReadingsMeansNoRecents() {
        #expect(MeasureFeature.State().recentReadings.isEmpty)
    }

    @Test internal func appearingRecordsTheCurrentDate() async {
        let now = Date(timeIntervalSince1970: 1_791_967_260)
        let store = makeStore {
            $0.date.now = now
        }

        await store.send(.onAppear) {
            $0.now = now
        }
    }

    @Test internal func dismissingTheHealthWarningClearsIt() async {
        let initialState = MeasureFeature.State()
        initialState.$healthWarning.withLock { $0 = "Saved on this iPhone, but Apple Health didn't accept it." }
        let store = makeStore(initialState)

        await store.send(.healthWarningDismissed) {
            $0.$healthWarning.withLock { $0 = nil }
        }
    }

    @Test internal func savingFromTheMeasurementStoresAndDismissesIt() async {
        let reading = PulseReading.previewReadings(now: Date(timeIntervalSince1970: 1_800_000_000))[0]
        let saved = LockIsolated<[PulseReading]>([])
        var measurement = MeasurementFeature.State(captureRate: 30)
        measurement.phase = .result(reading)
        var initialState = MeasureFeature.State()
        initialState.measurement = measurement
        let store = makeStore(initialState) {
            $0.readingStore.save = { reading, saveToHealth in
                #expect(saveToHealth)
                saved.withValue { $0.append(reading) }
            }
        }

        await store.send(.measurement(.presented(.saveTapped)))
        await store.receive(\.measurement.dismiss) {
            $0.measurement = nil
        }

        #expect(saved.value == [reading])
    }

    @Test internal func closingTheMeasurementBeforeAFingerDismissesIt() async {
        var initialState = MeasureFeature.State()
        initialState.measurement = MeasurementFeature.State(captureRate: 30)
        let store = makeStore(initialState)

        await store.send(.measurement(.presented(.closeTapped)))
        await store.receive(\.measurement.dismiss) {
            $0.measurement = nil
        }
    }

    private func makeStore(
        _ initialState: MeasureFeature.State = MeasureFeature.State(),
        dependencies: (inout DependencyValues) -> Void = { _ in }
    ) -> TestStoreOf<MeasureFeature> {
        TestStore(initialState: initialState) {
            MeasureFeature()
        } withDependencies: {
            $0.pulseSource.captureRate = { 30 }
            dependencies(&$0)
        }
    }
}
