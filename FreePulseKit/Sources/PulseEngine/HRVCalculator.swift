import Foundation

public struct HRVResult: Codable, Equatable, Sendable {
    /// Milliseconds.
    public var rmssd: Double
    /// Milliseconds.
    public var sdnn: Double
    /// Milliseconds.
    public var meanInterval: Double
    public var beatCount: Int

    public init(rmssd: Double, sdnn: Double, meanInterval: Double, beatCount: Int) {
        self.rmssd = rmssd
        self.sdnn = sdnn
        self.meanInterval = meanInterval
        self.beatCount = beatCount
    }
}

public enum HRVCalculator {
    public static let minimumAcceptedFraction = 0.8
    public static let minimumSpan: TimeInterval = 25
    public static let validInterval: ClosedRange<Double> = 0.3...1.5

    public static func intervals(from beatTimes: [TimeInterval]) -> [Double] {
        zip(beatTimes.dropFirst(), beatTimes).map { $0 - $1 }
    }

    /// Accepts intervals inside `validInterval` that are within 20% of the median of the 5 centred on them.
    public static func acceptanceMask(for intervals: [Double]) -> [Bool] {
        intervals.indices.map { index in
            let interval = intervals[index]
            guard validInterval.contains(interval) else { return false }
            let neighbours = Array(intervals[max(index - 2, 0)...min(index + 2, intervals.count - 1)])
            let localMedian = Stats.median(neighbours)
            return abs(interval - localMedian) <= 0.2 * localMedian
        }
    }

    /// Returns nil unless ≥ 80% of intervals are accepted and the accepted ones span ≥ 25 s.
    public static func compute(beatTimes: [TimeInterval]) -> HRVResult? {
        let all = intervals(from: beatTimes)
        guard !all.isEmpty else { return nil }
        let mask = acceptanceMask(for: all)
        let kept = zip(all, mask).filter(\.1).map(\.0)

        let acceptedFraction = Double(kept.count) / Double(all.count)
        guard acceptedFraction >= minimumAcceptedFraction, kept.reduce(0, +) >= minimumSpan else { return nil }

        let successiveDifferences = all.indices.dropFirst()
            .filter { mask[$0] && mask[$0 - 1] }
            .map { all[$0] - all[$0 - 1] }
        guard !successiveDifferences.isEmpty else { return nil }

        let rmssd = Stats.mean(successiveDifferences.map { $0 * $0 }).squareRoot()
        return HRVResult(
            rmssd: rmssd * 1000,
            sdnn: Stats.sampleStandardDeviation(kept) * 1000,
            meanInterval: Stats.mean(kept) * 1000,
            beatCount: beatTimes.count
        )
    }
}
