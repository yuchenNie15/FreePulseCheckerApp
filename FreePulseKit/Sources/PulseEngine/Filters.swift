import Foundation

/// Second-order Butterworth section (RBJ cookbook, Q = 1/√2) in transposed direct form II.
public struct Biquad: Equatable, Sendable {
    private let b0: Double
    private let b1: Double
    private let b2: Double
    private let a1: Double
    private let a2: Double
    private var z1 = 0.0
    private var z2 = 0.0

    private init(b0: Double, b1: Double, b2: Double, a0: Double, a1: Double, a2: Double) {
        self.b0 = b0 / a0
        self.b1 = b1 / a0
        self.b2 = b2 / a0
        self.a1 = a1 / a0
        self.a2 = a2 / a0
    }

    public static func lowPass(cutoff: Double, sampleRate: Double) -> Biquad {
        let (cosW, alpha) = coefficients(cutoff: cutoff, sampleRate: sampleRate)
        return Biquad(
            b0: (1 - cosW) / 2, b1: 1 - cosW, b2: (1 - cosW) / 2,
            a0: 1 + alpha, a1: -2 * cosW, a2: 1 - alpha
        )
    }

    public static func highPass(cutoff: Double, sampleRate: Double) -> Biquad {
        let (cosW, alpha) = coefficients(cutoff: cutoff, sampleRate: sampleRate)
        return Biquad(
            b0: (1 + cosW) / 2, b1: -(1 + cosW), b2: (1 + cosW) / 2,
            a0: 1 + alpha, a1: -2 * cosW, a2: 1 - alpha
        )
    }

    public static func process(_ x: Double, _ filter: inout Biquad) -> Double {
        let y = filter.b0 * x + filter.z1
        filter.z1 = filter.b1 * x - filter.a1 * y + filter.z2
        filter.z2 = filter.b2 * x - filter.a2 * y
        return y
    }

    private static func coefficients(cutoff: Double, sampleRate: Double) -> (cosW: Double, alpha: Double) {
        let w0 = 2 * Double.pi * cutoff / sampleRate
        return (cos(w0), sin(w0) / 2.0.squareRoot())
    }
}

/// Four-pole band-pass: a Butterworth high-pass and low-pass in series.
public struct BandPassFilter: Equatable, Sendable {
    /// 42–210 BPM.
    public static let heartRateBand: ClosedRange<Double> = 0.7...3.5

    private var highPass: Biquad
    private var lowPass: Biquad

    public init(sampleRate: Double, band: ClosedRange<Double> = heartRateBand) {
        highPass = .highPass(cutoff: band.lowerBound, sampleRate: sampleRate)
        lowPass = .lowPass(cutoff: band.upperBound, sampleRate: sampleRate)
    }

    public static func process(_ x: Double, _ filter: inout BandPassFilter) -> Double {
        Biquad.process(Biquad.process(x, &filter.highPass), &filter.lowPass)
    }

    /// Filters forwards then backwards, cancelling the phase delay so beat timing is preserved.
    public static func zeroPhase(
        _ signal: [Double],
        sampleRate: Double,
        band: ClosedRange<Double> = heartRateBand
    ) -> [Double] {
        var forward = BandPassFilter(sampleRate: sampleRate, band: band)
        let once = signal.map { process($0, &forward) }
        var backward = BandPassFilter(sampleRate: sampleRate, band: band)
        return Array(once.reversed().map { process($0, &backward) }.reversed())
    }
}

public struct MovingMean: Equatable, Sendable {
    private let capacity: Int
    private var values: [Double] = []
    private var head = 0
    private var sum = 0.0

    public init(windowCount: Int) {
        capacity = max(windowCount, 1)
    }

    /// Adds a value and returns the mean of the most recent `windowCount` values.
    public static func push(_ value: Double, _ mean: inout MovingMean) -> Double {
        if mean.values.count < mean.capacity {
            mean.values.append(value)
        } else {
            mean.sum -= mean.values[mean.head]
            mean.values[mean.head] = value
            mean.head = (mean.head + 1) % mean.capacity
        }
        mean.sum += value
        return mean.sum / Double(mean.values.count)
    }
}

/// Linearly interpolates an irregularly timed stream onto a fixed-rate grid anchored at the first sample.
public struct UniformResampler: Equatable, Sendable {
    public let rate: Double
    private var previous: TimedValue?
    private var start: TimeInterval = 0
    private var emitted = 0

    public init(rate: Double) {
        self.rate = rate
    }

    /// Returns the grid points between the previous sample and this one; out-of-order samples are dropped.
    public static func push(_ sample: TimedValue, _ resampler: inout UniformResampler) -> [TimedValue] {
        guard let previous = resampler.previous else {
            resampler.previous = sample
            resampler.start = sample.time
            resampler.emitted = 1
            return [sample]
        }
        guard sample.time > previous.time else { return [] }

        var output: [TimedValue] = []
        while true {
            let time = resampler.start + Double(resampler.emitted) / resampler.rate
            guard time <= sample.time else { break }
            let fraction = (time - previous.time) / (sample.time - previous.time)
            output.append(TimedValue(time: time, value: previous.value + fraction * (sample.value - previous.value)))
            resampler.emitted += 1
        }
        resampler.previous = sample
        return output
    }
}
