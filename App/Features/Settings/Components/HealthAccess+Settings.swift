import HealthKitClient

extension HealthAccess {
    internal var statusText: String {
        switch self {
        case .authorized: "Connected"
        case .notDetermined, .denied: "Not connected"
        case .unavailable: "Unavailable"
        }
    }

    internal var isTappable: Bool {
        self != .unavailable
    }
}
