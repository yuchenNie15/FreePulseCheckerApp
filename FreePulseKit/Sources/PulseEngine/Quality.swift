import Foundation

public struct QualityInputs: Equatable, Sendable {
    public var snrDecibels: Double
    /// Pulse amplitude as a fraction of brightness, e.g. 0.01 for 1%.
    public var perfusionIndex: Double
    /// Mean correlation of each beat with the average beat, -1...1.
    public var templateCorrelation: Double
    /// Fraction of samples free of motion and amplitude artifacts, 0...1.
    public var usableFraction: Double
    /// BPM gap between the spectral and beat-interval estimates; nil when there are too few beats.
    public var estimatorDisagreement: Double?

    public init(
        snrDecibels: Double,
        perfusionIndex: Double,
        templateCorrelation: Double,
        usableFraction: Double,
        estimatorDisagreement: Double?
    ) {
        self.snrDecibels = snrDecibels
        self.perfusionIndex = perfusionIndex
        self.templateCorrelation = templateCorrelation
        self.usableFraction = usableFraction
        self.estimatorDisagreement = estimatorDisagreement
    }
}

public enum QualityScorer {
    /// Below this SNR there is no dominant rhythm, so the score is capped at `noRhythmCap`.
    public static let minimumRhythmSNR = 2.0
    public static let noRhythmCap = 0.3

    /// Mean of five terms, each ramped linearly between its spec thresholds and clamped to 0...1.
    public static func score(_ inputs: QualityInputs) -> Double {
        let terms = [
            ramp(inputs.snrDecibels, from: 0, to: 6),
            perfusionTerm(inputs.perfusionIndex),
            ramp(inputs.templateCorrelation, from: 0.5, to: 0.9),
            ramp(inputs.usableFraction, from: 0.5, to: 1),
            inputs.estimatorDisagreement.map { 1 - ramp($0, from: 5, to: 15) } ?? 0,
        ]
        let mean = terms.reduce(0, +) / Double(terms.count)
        return inputs.snrDecibels < minimumRhythmSNR ? min(mean, noRhythmCap) : mean
    }

    private static func ramp(_ value: Double, from low: Double, to high: Double) -> Double {
        min(max((value - low) / (high - low), 0), 1)
    }

    private static func perfusionTerm(_ perfusionIndex: Double) -> Double {
        perfusionIndex <= 0.05
            ? ramp(perfusionIndex, from: 0.0005, to: 0.001)
            : 1 - ramp(perfusionIndex, from: 0.05, to: 0.10)
    }
}

public enum BeatTemplate {
    /// Mean Pearson correlation between each beat-aligned segment and their average; 0 with fewer than 3 beats.
    public static func correlation(signal: [TimedValue], beatTimes: [TimeInterval], sampleRate: Double) -> Double {
        let intervals = HRVCalculator.intervals(from: beatTimes).filter(HRVCalculator.validInterval.contains)
        guard !intervals.isEmpty else { return 0 }
        let length = Int(0.6 * Stats.median(intervals) * sampleRate)
        let lead = length / 5
        guard length > 3 else { return 0 }

        let segments: [[Double]] = beatTimes.compactMap { beat in
            let start = Stats.firstIndex(in: signal, atOrAfter: beat) - lead
            guard start >= 0, start + length <= signal.count else { return nil }
            return signal[start..<(start + length)].map(\.value)
        }
        guard segments.count >= 3 else { return 0 }

        let template = (0..<length).map { index in Stats.mean(segments.map { $0[index] }) }
        return Stats.mean(segments.map { Stats.pearson($0, template) })
    }
}

/// Marks the time around any accelerometer reading more than 0.05 g away from 1 g as motion.
public struct MotionLog: Equatable, Sendable {
    public static let threshold = 0.05
    public static let margin: TimeInterval = 0.5

    private var events: [TimeInterval] = []

    public init() {}

    public static func record(_ sample: MotionSample, _ log: inout MotionLog) {
        if abs(sample.magnitude - 1) > threshold {
            log.events.append(sample.timestamp)
        }
    }

    public func isStill(at time: TimeInterval) -> Bool {
        var low = 0
        var high = events.count
        while low < high {
            let middle = (low + high) / 2
            if events[middle] < time - Self.margin {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low == events.count || events[low] > time + Self.margin
    }
}

public enum ArtifactMask {
    /// True for samples taken while still and within 4 median absolute deviations of the median.
    public static func usableMask(_ samples: [TimedValue], motion: MotionLog) -> [Bool] {
        let values = samples.map(\.value)
        let median = Stats.median(values)
        let mad = Stats.median(values.map { abs($0 - median) })
        return samples.map { sample in
            motion.isStill(at: sample.time) && (mad == 0 || abs(sample.value - median) <= 4 * mad)
        }
    }

    public static func usableFraction(_ samples: [TimedValue], motion: MotionLog) -> Double {
        guard !samples.isEmpty else { return 0 }
        let mask = usableMask(samples, motion: motion)
        return Double(mask.filter { $0 }.count) / Double(mask.count)
    }
}

public enum Waveform {
    /// Evenly picks up to `count` points and scales them to -1...1.
    public static func displayPoints(_ values: [Double], count: Int) -> [Double] {
        guard !values.isEmpty, count > 0 else { return [] }
        let picked = values.count <= count
            ? values
            : (0..<count).map { values[$0 * values.count / count] }
        let peak = picked.map(abs).max() ?? 0
        return peak == 0 ? picked : picked.map { $0 / peak }
    }
}
