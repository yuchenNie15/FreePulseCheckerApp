import AppClients
import ComposableArchitecture
import Foundation
import HealthKitClient
import Testing
@testable import SettingsFeature

@MainActor
@Suite
internal struct SettingsFeatureTests {
    @Test(arguments: [HealthAccess.unavailable, .notDetermined, .authorized, .denied])
    internal func taskLoadsVersionAndAccess(access: HealthAccess) async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.appInfo.version = { "1.2 (34)" }
            $0.healthKit.access = { access }
        }

        await store.send(.task) {
            $0.appVersion = "1.2 (34)"
            $0.healthAccess = access
        }
    }

    @Test
    internal func sceneActiveRefreshesAccess() async {
        let access = LockIsolated(HealthAccess.denied)
        let store = TestStore(initialState: Self.loadedState(.denied)) {
            SettingsFeature()
        } withDependencies: {
            $0.healthKit.access = { access.value }
        }

        access.setValue(.authorized)
        await store.send(.sceneBecameActive) {
            $0.healthAccess = .authorized
        }
    }

    @Test
    internal func tapWhenNotDeterminedRequestsThenRefreshes() async {
        let access = LockIsolated(HealthAccess.notDetermined)
        let requests = LockIsolated(0)
        let store = TestStore(initialState: Self.loadedState(.notDetermined)) {
            SettingsFeature()
        } withDependencies: {
            $0.healthKit.access = { access.value }
            $0.healthKit.requestAuthorization = {
                requests.withValue { $0 += 1 }
                access.setValue(.authorized)
            }
        }

        await store.send(.healthRowTapped)
        await store.receive(\.authorizationCompleted) {
            $0.healthAccess = .authorized
        }
        #expect(requests.value == 1)
    }

    @Test
    internal func tapWhenNotDeterminedAndRequestThrowsLeavesStatus() async {
        let requests = LockIsolated(0)
        let store = TestStore(initialState: Self.loadedState(.notDetermined)) {
            SettingsFeature()
        } withDependencies: {
            $0.healthKit.access = { .denied }
            $0.healthKit.requestAuthorization = {
                requests.withValue { $0 += 1 }
                throw AuthorizationError()
            }
        }

        await store.send(.healthRowTapped)
        await store.finish()
        #expect(requests.value == 1)
        #expect(store.state.healthAccess == .notDetermined)
    }

    @Test(arguments: [HealthAccess.authorized, .denied])
    internal func tapWhenDecidedOpensHealthApp(access: HealthAccess) async {
        let openedURLs = LockIsolated<[URL]>([])
        let store = TestStore(initialState: Self.loadedState(access)) {
            SettingsFeature()
        } withDependencies: {
            $0.openURL = OpenURLEffect { url in
                openedURLs.withValue { $0.append(url) }
                return true
            }
        }

        await store.send(.healthRowTapped)
        await store.finish()
        #expect(openedURLs.value == [URL(string: "x-apple-health://")!])
    }

    @Test
    internal func tapWhenUnavailableDoesNothing() async {
        let store = TestStore(initialState: Self.loadedState(.unavailable)) {
            SettingsFeature()
        }

        await store.send(.healthRowTapped)
    }

    @Test
    internal func tapBeforeFirstRefreshDoesNothing() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.healthRowTapped)
    }

    @Test
    internal func disclaimerPushesAndPops() async {
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.path(.push(id: 0, state: .disclaimer))) {
            $0.path[id: 0] = .disclaimer
        }
        await store.send(.path(.popFrom(id: 0))) {
            $0.path = StackState()
        }
    }

    @Test
    internal func licensesThenDetailPushAndPop() async throws {
        let climbPulse = try #require(License.all.first { $0.id == "climbpulse" })
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }

        await store.send(.path(.push(id: 0, state: .licenses))) {
            $0.path[id: 0] = .licenses
        }
        await store.send(.path(.push(id: 1, state: .license(climbPulse)))) {
            $0.path[id: 1] = .license(climbPulse)
        }
        await store.send(.path(.popFrom(id: 1))) {
            $0.path.removeLast()
        }
        await store.send(.path(.popFrom(id: 0))) {
            $0.path = StackState()
        }
    }

    @Test
    internal func licensesCoverEveryDependencyWithFullText() {
        let ids = License.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(Set(ids) == Self.expectedLicenseIDs)
        for license in License.all {
            #expect(license.text.contains("THE SOFTWARE IS PROVIDED") || license.text.contains("Apache License"))
        }
        let climbPulse = License.all.first { $0.id == "climbpulse" }
        #expect(climbPulse?.text.contains("Copyright (c) 2024 University of Jyväskylä (JYU)") == true)
    }

    private static let expectedLicenseIDs: Set<String> = [
        "composable-architecture", "combine-schedulers", "swift-case-paths", "swift-clocks",
        "swift-concurrency-extras", "swift-custom-dump", "swift-dependencies",
        "swift-identified-collections", "swift-issue-reporting", "swift-navigation",
        "swift-perception", "swift-sharing", "swift-collections", "swift-syntax", "climbpulse",
    ]

    private static func loadedState(_ access: HealthAccess) -> SettingsFeature.State {
        var state = SettingsFeature.State()
        state.appVersion = "1.2 (34)"
        state.healthAccess = access
        return state
    }
}

private struct AuthorizationError: Error {}
