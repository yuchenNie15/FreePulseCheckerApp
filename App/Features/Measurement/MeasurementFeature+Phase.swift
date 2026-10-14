import Models
import PulseSourceClient

extension MeasurementFeature {
    internal enum Phase: Equatable, Sendable {
        case preparing
        case waitingForFinger
        case calibrating
        case measuring
        case paused
        case result(PulseReading)
        case failed(FailureReason)
    }

    internal enum FailureReason: Equatable, Sendable {
        case fingerLifted
        case unreliable
        case cameraUnavailable
        case overheated
        case interrupted
    }
}

extension MeasurementFeature.Phase {
    /// The camera is running and no outcome exists yet.
    internal var isActive: Bool {
        switch self {
        case .preparing, .waitingForFinger, .calibrating, .measuring, .paused: true
        case .result, .failed: false
        }
    }

    /// Names the phase without the reading a `.result` carries, so it is safe for the public log.
    internal var logDescription: String {
        switch self {
        case .preparing: "preparing"
        case .waitingForFinger: "waitingForFinger"
        case .calibrating: "calibrating"
        case .measuring: "measuring"
        case .paused: "paused"
        case .result: "result"
        case let .failed(reason): "failed(\(reason))"
        }
    }

    internal var needsStopConfirmation: Bool {
        switch self {
        case .calibrating, .measuring, .paused: true
        case .preparing, .waitingForFinger, .result, .failed: false
        }
    }
}

extension MeasurementFeature.FailureReason {
    internal init(_ error: any Error) {
        switch error as? PulseSourceError {
        case .overheated: self = .overheated
        case .interrupted: self = .interrupted
        case .cameraUnavailable, .configurationFailed, nil: self = .cameraUnavailable
        }
    }
}
