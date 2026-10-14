import ComposableArchitecture
import Foundation

extension SharedKey where Self == FileStorageKey<IdentifiedArrayOf<PulseReading>>.Default {
    /// Every saved reading, newest first.
    public static var readings: Self {
        Self[.fileStorage(.documentsDirectory.appending(component: "readings.json")), default: []]
    }
}
