import ComposableArchitecture
import HealthKitClient
import Models

/** Persists readings and mirrors them to Apple Health.
- `save` inserts locally first, so a Health failure never loses a reading; it then sets `.healthWarning`.
- Health authorization is requested on the first save that asks for it. */
@DependencyClient
public struct ReadingStore: Sendable {
    public var save: @Sendable (_ reading: PulseReading, _ saveToHealth: Bool) async -> Void
    public var delete: @Sendable (_ id: PulseReading.ID) -> Void
}

extension ReadingStore: DependencyKey {
    public static let liveValue = ReadingStore(
        save: { reading, saveToHealth in
            @Shared(.readings) var readings
            @Shared(.healthWarning) var healthWarning
            @Dependency(\.healthKit) var healthKit

            $readings.withLock { $0.insert(reading, at: 0) }
            guard saveToHealth else { return }
            do {
                if healthKit.access() == .notDetermined {
                    try await healthKit.requestAuthorization()
                }
                guard healthKit.access() == .authorized else {
                    $healthWarning.withLock { $0 = "Saved on this iPhone. Apple Health access is off." }
                    return
                }
                try await healthKit.save(reading)
                $readings.withLock { $0[id: reading.id]?.savedToHealth = true }
            } catch {
                $healthWarning.withLock { $0 = "Saved on this iPhone, but Apple Health didn't accept it." }
            }
        },
        delete: { id in
            @Shared(.readings) var readings
            $readings.withLock { _ = $0.remove(id: id) }
        }
    )

    public static let testValue = ReadingStore()
}

extension DependencyValues {
    public var readingStore: ReadingStore {
        get { self[ReadingStore.self] }
        set { self[ReadingStore.self] = newValue }
    }
}
