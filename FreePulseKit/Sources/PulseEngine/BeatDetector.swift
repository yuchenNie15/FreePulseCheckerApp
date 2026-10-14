import Foundation

/** Detects heartbeats as the steepest point of each systolic upstroke in a band-passed pulse signal.
- A slope peak counts when it exceeds the rolling 2 s slope mean by 0.3 × the rolling slope range.
- Peaks closer than half the expected interbeat interval (bounded to 250–1000 ms) to the last beat are ignored.
- Beat times are refined between samples by parabolic interpolation. */
public struct BeatDetector: Equatable, Sendable {
    private let sampleRate: Double
    private let historyCount: Int
    private var slopeHistory: [Double] = []
    private var recentSlopes: [TimedValue] = []
    private var previous: TimedValue?
    private var lastBeat: TimeInterval?
    private var recentIntervals: [Double] = []

    /// Seeds the refractory period until enough beats have been seen; seconds.
    public var expectedInterval: TimeInterval?

    public init(sampleRate: Double, expectedInterval: TimeInterval? = nil) {
        self.sampleRate = sampleRate
        self.expectedInterval = expectedInterval
        historyCount = Int(2 * sampleRate)
    }

    /// Returns the time of a beat detected one sample behind `time`, if any.
    public static func process(_ value: Double, at time: TimeInterval, _ detector: inout BeatDetector) -> TimeInterval? {
        guard let previous = detector.previous else {
            detector.previous = TimedValue(time: time, value: value)
            return nil
        }
        detector.previous = TimedValue(time: time, value: value)

        let slope = (value - previous.value) / (time - previous.time)
        detector.slopeHistory.append(slope)
        if detector.slopeHistory.count > detector.historyCount {
            detector.slopeHistory.removeFirst()
        }
        detector.recentSlopes.append(TimedValue(time: (time + previous.time) / 2, value: slope))
        if detector.recentSlopes.count > 3 {
            detector.recentSlopes.removeFirst()
        }

        guard detector.recentSlopes.count == 3, detector.slopeHistory.count >= Int(detector.sampleRate) else { return nil }
        let (a, b, c) = (detector.recentSlopes[0], detector.recentSlopes[1], detector.recentSlopes[2])
        guard b.value > a.value, b.value >= c.value else { return nil }

        let range = (detector.slopeHistory.max() ?? 0) - (detector.slopeHistory.min() ?? 0)
        guard b.value > Stats.mean(detector.slopeHistory) + 0.3 * range else { return nil }

        let beat = b.time + parabolicOffset(a.value, b.value, c.value) * (c.time - a.time) / 2
        if let lastBeat = detector.lastBeat {
            let interval = beat - lastBeat
            guard interval >= refractoryPeriod(detector) else { return nil }
            if (0.3...1.5).contains(interval) {
                detector.recentIntervals.append(interval)
                if detector.recentIntervals.count > 5 {
                    detector.recentIntervals.removeFirst()
                }
            }
        }
        detector.lastBeat = beat
        return beat
    }

    private static func refractoryPeriod(_ detector: BeatDetector) -> TimeInterval {
        let expected = detector.recentIntervals.isEmpty
            ? (detector.expectedInterval ?? 0.5)
            : Stats.median(detector.recentIntervals)
        return min(max(0.5 * expected, 0.25), 1.0)
    }

    private static func parabolicOffset(_ left: Double, _ center: Double, _ right: Double) -> Double {
        let denominator = left - 2 * center + right
        guard denominator != 0 else { return 0 }
        return min(max(0.5 * (left - right) / denominator, -0.5), 0.5)
    }
}
