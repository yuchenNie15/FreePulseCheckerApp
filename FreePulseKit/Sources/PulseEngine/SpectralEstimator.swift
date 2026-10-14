import Foundation

public struct SpectralEstimate: Equatable, Sendable {
    public var bpm: Double
    /// Power within ±12 BPM of the heart rate and its 2nd and 3rd harmonics, relative to the rest of the band.
    public var snrDecibels: Double

    public init(bpm: Double, snrDecibels: Double) {
        self.bpm = bpm
        self.snrDecibels = snrDecibels
    }
}

/** Finds the dominant heart rate with a Hann-windowed DFT evaluated on a 0.25 BPM grid.
- Goertzel per grid frequency keeps the work to the heart-rate band, with no padding or FFT setup.
- If a half or third of the peak frequency carries ≥ 50% of its power, the peak is taken to be a harmonic. */
public enum SpectralEstimator {
    public static let bpmRange: ClosedRange<Double> = 42...210
    public static let bpmStep = 0.25

    /// An 8 s Hann window spreads a pure tone across roughly ±15 BPM.
    private static let signalHalfWidth = 12.0
    private static let grid: [Double] = Array(stride(from: bpmRange.lowerBound, through: bpmRange.upperBound, by: bpmStep))

    /// Returns nil for signals shorter than 4 s or with no power in the band.
    public static func estimate(_ signal: [Double], sampleRate: Double) -> SpectralEstimate? {
        guard Double(signal.count) >= sampleRate * 4 else { return nil }
        let windowed = hannWindowed(signal)
        let power = grid.map { goertzelPower(windowed, frequency: $0 / 60, sampleRate: sampleRate) }
        guard let peak = power.indices.max(by: { power[$0] < power[$1] }), power[peak] > 0 else { return nil }

        var index = peak
        for divisor in [3.0, 2.0] where grid[peak] / divisor >= bpmRange.lowerBound {
            let candidate = localMaximum(in: power, near: gridIndex(for: grid[peak] / divisor))
            if power[candidate] >= 0.5 * power[peak] {
                index = candidate
                break
            }
        }

        let bpm = refined(index, in: power)
        return SpectralEstimate(bpm: bpm, snrDecibels: snr(power, bpm: bpm))
    }

    private static func hannWindowed(_ signal: [Double]) -> [Double] {
        let mean = Stats.mean(signal)
        let last = Double(signal.count - 1)
        return signal.enumerated().map { n, x in
            (x - mean) * 0.5 * (1 - cos(2 * Double.pi * Double(n) / last))
        }
    }

    private static func goertzelPower(_ signal: [Double], frequency: Double, sampleRate: Double) -> Double {
        let coefficient = 2 * cos(2 * Double.pi * frequency / sampleRate)
        var s1 = 0.0
        var s2 = 0.0
        for x in signal {
            let s = x + coefficient * s1 - s2
            s2 = s1
            s1 = s
        }
        return s1 * s1 + s2 * s2 - coefficient * s1 * s2
    }

    private static func gridIndex(for bpm: Double) -> Int {
        min(max(Int(((bpm - bpmRange.lowerBound) / bpmStep).rounded()), 0), grid.count - 1)
    }

    private static func localMaximum(in power: [Double], near index: Int) -> Int {
        let range = max(index - 4, 0)...min(index + 4, power.count - 1)
        return range.max(by: { power[$0] < power[$1] }) ?? index
    }

    private static func refined(_ index: Int, in power: [Double]) -> Double {
        guard index > 0, index < power.count - 1 else { return grid[index] }
        let (left, center, right) = (power[index - 1], power[index], power[index + 1])
        let denominator = left - 2 * center + right
        let offset = denominator == 0 ? 0 : 0.5 * (left - right) / denominator
        return grid[index] + min(max(offset, -0.5), 0.5) * bpmStep
    }

    private static func snr(_ power: [Double], bpm: Double) -> Double {
        var signal = 0.0
        var noise = 0.0
        for (index, value) in power.enumerated() {
            let isNearPeak = (1...3).contains { abs(grid[index] - Double($0) * bpm) <= signalHalfWidth }
            if isNearPeak {
                signal += value
            } else {
                noise += value
            }
        }
        guard noise > 0 else { return 60 }
        guard signal > 0 else { return -60 }
        return 10 * log10(signal / noise)
    }
}
