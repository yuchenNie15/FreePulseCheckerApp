import Foundation

/** Decides when to freeze exposure, white balance and focus so auto-exposure can't flatten the pulse.
- Locks once the finger has covered the lens for `settleTime`, and returns to auto after it has been off as long. */
internal struct ExposureLock: Equatable, Sendable {
    internal enum Action: Equatable, Sendable {
        case lock
        case unlock
    }

    internal static let settleTime: TimeInterval = 1

    internal private(set) var isLocked = false
    private var changeRequestedAt: TimeInterval?

    internal init() {}

    /** Folds one frame into the lock and returns the change to apply, if any.
    - Parameter fingerOnLens: Whether this frame classifies as a fingertip fully covering the lens.
    - Parameter time: The frame's timestamp in seconds.
    - Parameter lock: The lock to update. */
    internal static func update(fingerOnLens: Bool, at time: TimeInterval, _ lock: inout ExposureLock) -> Action? {
        guard fingerOnLens != lock.isLocked else {
            lock.changeRequestedAt = nil
            return nil
        }
        let requestedAt = lock.changeRequestedAt ?? time
        guard time - requestedAt >= settleTime else {
            lock.changeRequestedAt = requestedAt
            return nil
        }
        lock.isLocked = fingerOnLens
        lock.changeRequestedAt = nil
        return fingerOnLens ? .lock : .unlock
    }
}
