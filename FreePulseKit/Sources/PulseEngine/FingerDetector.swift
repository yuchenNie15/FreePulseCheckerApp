import Foundation

/** Classifies whether a fingertip covers the lens, with hysteresis so the state doesn't flicker.
- Entering `.present` takes `framesToEnter` consecutive finger frames; leaving it takes `framesToExit`.
- `.tooMuchPressure` replaces `.present` once the perfusion index stays below 0.05% for 2 s. */
public struct FingerDetector: Equatable, Sendable {
    public static let framesToEnter = 10
    public static let framesToExit = 6

    public private(set) var state: FingerState = .absent
    private var fingerStreak = 0
    private var noFingerStreak = 0
    private var lowPerfusionSince: TimeInterval?

    public init() {}

    /** Folds one frame into the detector and returns its new state.
    - Parameter frame: The latest camera frame.
    - Parameter perfusionIndex: Pulse amplitude as a fraction of brightness, or nil before enough signal exists.
    - Parameter detector: The detector to update. */
    public static func update(
        with frame: PPGFrame,
        perfusionIndex: Double?,
        _ detector: inout FingerDetector
    ) -> FingerState {
        let raw = classify(frame)
        if raw == .present {
            detector.fingerStreak += 1
            detector.noFingerStreak = 0
        } else {
            detector.noFingerStreak += 1
            detector.fingerStreak = 0
        }

        let onLens = detector.state.isOnLens
            ? detector.noFingerStreak < framesToExit
            : detector.fingerStreak >= framesToEnter

        if onLens {
            detector.state = pressureAdjustedState(at: frame.timestamp, perfusionIndex: perfusionIndex, &detector)
        } else {
            detector.lowPerfusionSince = nil
            if raw != .present {
                detector.state = raw
            }
        }
        return detector.state
    }

    /// Classifies a single frame without hysteresis.
    public static func classify(_ frame: PPGFrame) -> FingerState {
        guard !frame.cells.isEmpty else { return .absent }
        if frame.red < 40 { return .tooDark }

        let fingerCells = frame.cells.filter { $0.meanRed > 90 && $0.meanRed >= 2 * $0.meanGreen }
        let coverage = Double(fingerCells.count) / Double(frame.cells.count)
        if coverage < 0.5 { return .absent }
        if coverage < 0.9 { return .partial }
        if Stats.coefficientOfVariation(frame.cells.map(\.meanRed)) > 0.15 { return .absent }
        if frame.saturatedFraction > 0.3 { return .saturated }
        return .present
    }

    private static func pressureAdjustedState(
        at time: TimeInterval,
        perfusionIndex: Double?,
        _ detector: inout FingerDetector
    ) -> FingerState {
        guard let perfusionIndex, perfusionIndex < 0.0005 else {
            detector.lowPerfusionSince = nil
            return .present
        }
        let since = detector.lowPerfusionSince ?? time
        detector.lowPerfusionSince = since
        return time - since >= 2 ? .tooMuchPressure : .present
    }
}
