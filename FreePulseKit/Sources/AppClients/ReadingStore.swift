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
            @Dependency(\.log) var log

            $readings.withLock { _ = $0.insert(reading, at: 0) }
            log.write(LogEntry(.info, .readingStore, "Saved reading \(reading.id) locally"))
            guard saveToHealth else { return }
            do {
                if healthKit.access() == .notDetermined {
                    log.write(LogEntry(.info, .readingStore, "Requesting Health authorization before saving"))
                    try await healthKit.requestAuthorization()
                }
                guard healthKit.access() == .authorized else {
                    log.write(LogEntry(.info, .readingStore, "Health access is off; skipped the Health write"))
                    $healthWarning.withLock { $0 = "Saved on this iPhone. Apple Health access is off." }
                    return
                }
                try await healthKit.save(reading)
                $readings.withLock { readings in readings[id: reading.id]?.savedToHealth = true }
                log.write(LogEntry(.info, .readingStore, "Saved reading \(reading.id) to Health"))
            } catch {
                log.write(LogEntry(.error, .readingStore, "Health rejected reading \(reading.id): \(error)"))
                $healthWarning.withLock { $0 = "Saved on this iPhone, but Apple Health didn't accept it." }
            }
        },
        delete: { id in
            @Shared(.readings) var readings
            @Dependency(\.log) var log
            $readings.withLock { _ = $0.remove(id: id) }
            log.write(LogEntry(.info, .readingStore, "Deleted reading \(id)"))
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
