import ComposableArchitecture
import Foundation
import PulseEngine

public enum PulseSourceEvent: Equatable, Sendable {
    case frame(PPGFrame)
    case motion(MotionSample)
}

public enum PulseSourceError: Error, Equatable, Sendable {
    case cameraUnavailable
    case configurationFailed
    case overheated
    case interrupted
}

/** Streams camera frames and accelerometer samples for one measurement.
- The torch is on while a stream is being consumed and turns off when the consumer cancels. */
@DependencyClient
public struct PulseSourceClient: Sendable {
    /// Frame rate in Hz that `events` will deliver.
    public var captureRate: @Sendable () -> Double = { 60 }
    public var events: @Sendable () async -> AsyncThrowingStream<PulseSourceEvent, any Error> = { .finished() }
}

extension PulseSourceClient: DependencyKey {
    public static let liveValue: PulseSourceClient = {
        #if targetEnvironment(simulator)
        return .simulated(bpm: 72)
        #else
        return PulseSourceClient(
            captureRate: { 60 },
            events: { AsyncThrowingStream { $0.finish(throwing: PulseSourceError.cameraUnavailable) } }
        )
        #endif
    }()

    public static let previewValue = PulseSourceClient.simulated(bpm: 72)
    public static let testValue = PulseSourceClient()
}

extension DependencyValues {
    public var pulseSource: PulseSourceClient {
        get { self[PulseSourceClient.self] }
        set { self[PulseSourceClient.self] = newValue }
    }
}
