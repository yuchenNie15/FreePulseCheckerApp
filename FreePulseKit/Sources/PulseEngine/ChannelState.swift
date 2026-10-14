import Foundation

internal enum Channel: Equatable, Sendable {
    case red
    case green
}

/** One colour channel's processing chain.
- Brightness becomes `1 - brightness / mean₁.₅ₛ`, so blood-volume pulses point upwards.
- Both paths are resampled onto uniform grids before filtering; the filters and slope detection assume even spacing.
- The first 2 s after a start or interruption only warm the filters and are not recorded. */
internal struct ChannelState: Equatable, Sendable {
    private let captureRate: Double
    private var baseline: MovingMean
    private var captureFilter: BandPassFilter
    private var bpmFilter: BandPassFilter
    private var captureResampler: UniformResampler
    private var bpmResampler: UniformResampler
    private var warmupRemaining: Int

    internal var beatDetector: BeatDetector
    internal private(set) var normalized: [TimedValue] = []
    internal private(set) var filtered: [TimedValue] = []
    internal private(set) var bpmSeries: [TimedValue] = []
    internal private(set) var beats: [TimeInterval] = []

    internal init(captureRate: Double, expectedInterval: TimeInterval? = nil) {
        self.captureRate = captureRate
        baseline = MovingMean(windowCount: Int(1.5 * captureRate))
        captureFilter = BandPassFilter(sampleRate: captureRate)
        bpmFilter = BandPassFilter(sampleRate: PulseAnalysis.bpmSampleRate)
        captureResampler = UniformResampler(rate: captureRate)
        bpmResampler = UniformResampler(rate: PulseAnalysis.bpmSampleRate)
        beatDetector = BeatDetector(sampleRate: captureRate, expectedInterval: expectedInterval)
        warmupRemaining = Int(2 * captureRate)
    }

    internal static func process(_ brightness: Double, at time: TimeInterval, _ channel: inout ChannelState) {
        let mean = MovingMean.push(brightness, &channel.baseline)
        guard mean > 0 else { return }
        let sample = TimedValue(time: time, value: 1 - brightness / mean)
        let uniform = UniformResampler.push(sample, &channel.captureResampler)
        let filteredUniform = uniform.map {
            TimedValue(time: $0.time, value: BandPassFilter.process($0.value, &channel.captureFilter))
        }
        let resampled = UniformResampler.push(sample, &channel.bpmResampler).map {
            TimedValue(time: $0.time, value: BandPassFilter.process($0.value, &channel.bpmFilter))
        }

        if channel.warmupRemaining > 0 {
            channel.warmupRemaining -= 1
            return
        }
        channel.normalized.append(contentsOf: uniform)
        channel.filtered.append(contentsOf: filteredUniform)
        channel.bpmSeries.append(contentsOf: resampled)
        for point in filteredUniform {
            if let beat = BeatDetector.process(point.value, at: point.time, &channel.beatDetector) {
                channel.beats.append(beat)
            }
        }
    }

    /// Restarts the filters after the finger leaves the lens, keeping everything recorded so far.
    internal static func interrupt(_ channel: inout ChannelState) {
        channel.baseline = MovingMean(windowCount: Int(1.5 * channel.captureRate))
        channel.captureFilter = BandPassFilter(sampleRate: channel.captureRate)
        channel.bpmFilter = BandPassFilter(sampleRate: PulseAnalysis.bpmSampleRate)
        channel.captureResampler = UniformResampler(rate: channel.captureRate)
        channel.bpmResampler = UniformResampler(rate: PulseAnalysis.bpmSampleRate)
        channel.beatDetector = BeatDetector(sampleRate: channel.captureRate, expectedInterval: channel.beatDetector.expectedInterval)
        channel.warmupRemaining = Int(2 * channel.captureRate)
    }
}
