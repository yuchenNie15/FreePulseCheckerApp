import ComposableArchitecture
import Foundation
import HealthKit
import Models

public enum HealthAccess: Equatable, Sendable {
    case unavailable
    case notDetermined
    case authorized
    case denied
}

@DependencyClient
public struct HealthKitClient: Sendable {
    /// Sharing status for heart rate, which gates every write.
    public var access: @Sendable () -> HealthAccess = { .unavailable }
    public var requestAuthorization: @Sendable () async throws -> Void
    /// Writes the heart rate, plus HRV SDNN when the reading has one.
    public var save: @Sendable (_ reading: PulseReading) async throws -> Void
}

extension HealthKitClient: DependencyKey {
    public static let liveValue: HealthKitClient = {
        let store = HKHealthStore()
        let heartRate = HKQuantityType(.heartRate)
        let variability = HKQuantityType(.heartRateVariabilitySDNN)
        return HealthKitClient(
            access: {
                guard HKHealthStore.isHealthDataAvailable() else { return .unavailable }
                switch store.authorizationStatus(for: heartRate) {
                case .notDetermined: return .notDetermined
                case .sharingAuthorized: return .authorized
                default: return .denied
                }
            },
            requestAuthorization: {
                try await store.requestAuthorization(toShare: [heartRate, variability], read: [])
            },
            save: { reading in
                var samples = [
                    HKQuantitySample(
                        type: heartRate,
                        quantity: HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: Double(reading.bpm)),
                        start: reading.date,
                        end: reading.date
                    ),
                ]
                if let sdnn = reading.sdnn {
                    samples.append(HKQuantitySample(
                        type: variability,
                        quantity: HKQuantity(unit: .secondUnit(with: .milli), doubleValue: sdnn),
                        start: reading.date,
                        end: reading.date
                    ))
                }
                try await store.save(samples)
            }
        )
    }()

    public static let previewValue = HealthKitClient(
        access: { .authorized },
        requestAuthorization: {},
        save: { _ in }
    )
    public static let testValue = HealthKitClient()
}

extension DependencyValues {
    public var healthKit: HealthKitClient {
        get { self[HealthKitClient.self] }
        set { self[HealthKitClient.self] = newValue }
    }
}
