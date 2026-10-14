import AppClients
import ComposableArchitecture
import Foundation
import Models
import PulseEngine
import PulseSourceClient
import SwiftUI
import Testing
@testable import FreePulseCheck

extension MeasurementFeatureTests {
    @MainActor
    @Suite internal struct Save {
        @Test internal func saveStoresTheReadingWithHealthAndDismisses() async {
            let saves = LockIsolated<[SaveCall]>([])
            let dismissed = LockIsolated(false)
            let store = makeStore(state(.result(reading))) {
                $0.readingStore.save = { reading, saveToHealth in
                    saves.withValue { $0.append(SaveCall(reading: reading, saveToHealth: saveToHealth)) }
                }
                $0.dismiss = DismissEffect { dismissed.setValue(true) }
            }

            await store.send(.saveTapped)
            await store.finish()

            #expect(saves.value == [SaveCall(reading: reading, saveToHealth: true)])
            #expect(dismissed.value)
        }

        @Test internal func turningHealthOffSavesOnlyLocally() async {
            let saves = LockIsolated<[SaveCall]>([])
            let store = makeStore(state(.result(reading))) {
                $0.readingStore.save = { reading, saveToHealth in
                    saves.withValue { $0.append(SaveCall(reading: reading, saveToHealth: saveToHealth)) }
                }
                $0.dismiss = DismissEffect {}
            }

            await store.send(.binding(.set(\.saveToHealth, false))) {
                $0.saveToHealth = false
            }
            await store.send(.saveTapped)
            await store.finish()

            #expect(saves.value == [SaveCall(reading: reading, saveToHealth: false)])
        }

        @Test internal func discardDismissesWithoutSaving() async {
            let dismissed = LockIsolated(false)
            let store = makeStore(state(.result(reading))) {
                $0.dismiss = DismissEffect { dismissed.setValue(true) }
            }

            await store.send(.discardTapped)
            await store.finish()

            #expect(dismissed.value)
        }
    }
}

private struct SaveCall: Equatable, Sendable {
    internal let reading: PulseReading
    internal let saveToHealth: Bool
}
