import ComposableArchitecture
import Foundation

public struct PulseSnapshot: Equatable, Sendable {
    public var fingerState: FingerState
    /// Nil until a reading reaches Fair quality.
    public var bpm: Int?
    public var quality: SignalQuality?
    public var qualityScore: Double?
    /// The last 4 s of pulse scaled to -1...1, at most 120 points.
    public var waveform: [Double]

    public init(
        fingerState: FingerState,
        bpm: Int? = nil,
        quality: SignalQuality? = nil,
        qualityScore: Double? = nil,
        waveform: [Double] = []
    ) {
        self.fingerState = fingerState
        self.bpm = bpm
        self.quality = quality
        self.qualityScore = qualityScore
        self.waveform = waveform
    }
}

public struct PulseSummary: Equatable, Sendable {
    public var bpm: Int
    public var quality: SignalQuality
    public var qualityScore: Double
    /// Nil when too few clean beats were found.
    public var hrv: HRVResult?
    /// Accepted interbeat intervals, seconds.
    public var beatIntervals: [Double]
    /// A 5 s excerpt of pulse scaled to -1...1, 100 points.
    public var waveform: [Double]

    public init(
        bpm: Int,
        quality: SignalQuality,
        qualityScore: Double,
        hrv: HRVResult?,
        beatIntervals: [Double],
        waveform: [Double]
    ) {
        self.bpm = bpm
        self.quality = quality
        self.qualityScore = qualityScore
        self.hrv = hrv
        self.beatIntervals = beatIntervals
        self.waveform = waveform
    }
}

public enum PulseAnalysisError: Error, Equatable, Sendable {
    case unreliable
}

/** Turns camera frames and motion samples into a live `snapshot` and, at the end, a `PulseSummary`.
- `snapshot` refreshes every 0.25 s of frame time; nothing else in the state is observed.
- Red and green are processed in parallel; the one with the higher spectral SNR is used, re-chosen every 2 s. */
@Reducer
public struct PulseAnalysis: Sendable {
    public static let bpmSampleRate = 30.0
    public static let estimationWindow: TimeInterval = 8
    public static let snapshotInterval: TimeInterval = 0.25

    @ObservableState
    public struct State: Equatable, Sendable {
        public var snapshot = PulseSnapshot(fingerState: .absent)
        public var measuringStart: TimeInterval?

        @ObservationStateIgnored public let captureRate: Double
        @ObservationStateIgnored var finger = FingerDetector()
        @ObservationStateIgnored var red: ChannelState
        @ObservationStateIgnored var green: ChannelState
        @ObservationStateIgnored var motion = MotionLog()
        @ObservationStateIgnored var selected = Channel.green
        @ObservationStateIgnored var lastSelectionTime: TimeInterval?
        @ObservationStateIgnored var lastSnapshotTime: TimeInterval?
        @ObservationStateIgnored var latestSaturation = 0.0
        @ObservationStateIgnored var latestPerfusion: Double?
        @ObservationStateIgnored var latestTime: TimeInterval = 0

        /// - Parameter captureRate: Nominal camera frame rate in Hz.
        public init(captureRate: Double) {
            self.captureRate = captureRate
            red = ChannelState(captureRate: captureRate)
            green = ChannelState(captureRate: captureRate)
        }
    }

    public enum Action: Equatable, Sendable {
        case frame(PPGFrame)
        case motion(MotionSample)
        /// Marks the latest frame as the start of the phase that `State.summarize()` covers.
        case beginMeasuring
        case reset
    }

    @Dependency(\.pulseAnalyzer) private var analyzer

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .frame(frame):
                analyzer.ingest(frame, &state)
            case let .motion(sample):
                MotionLog.record(sample, &state.motion)
            case .beginMeasuring:
                state.measuringStart = state.latestTime
            case .reset:
                state = State(captureRate: state.captureRate)
            }
            return .none
        }
    }

    /// The live frame step behind `PulseAnalyzer.ingest`.
    public static func ingest(_ frame: PPGFrame, _ state: inout State) {
        state.latestTime = frame.timestamp
        state.latestSaturation = frame.saturatedFraction
        let fingerState = FingerDetector.update(with: frame, perfusionIndex: state.latestPerfusion, &state.finger)
        if fingerState.isOnLens {
            ChannelState.process(frame.red, at: frame.timestamp, &state.red)
            ChannelState.process(frame.green, at: frame.timestamp, &state.green)
        } else {
            ChannelState.interrupt(&state.red)
            ChannelState.interrupt(&state.green)
            state.latestPerfusion = nil
        }

        if let last = state.lastSnapshotTime, frame.timestamp - last < snapshotInterval { return }
        state.lastSnapshotTime = frame.timestamp
        state.snapshot = snapshot(&state)
    }

    private static func snapshot(_ state: inout State) -> PulseSnapshot {
        let fingerState = state.finger.state
        guard fingerState.isOnLens else { return PulseSnapshot(fingerState: fingerState) }

        reselectChannelIfNeeded(&state)
        let channel = state.selected == .red ? state.red : state.green
        let windowStart = state.latestTime - estimationWindow
        let filtered = Stats.suffix(of: channel.filtered, from: windowStart)
        let recent = Stats.suffix(of: filtered, from: state.latestTime - 4)
        let waveform = Waveform.displayPoints(recent.map(\.value), count: 120)
        state.latestPerfusion = perfusionIndex(recent)

        let bpmWindow = Stats.suffix(of: channel.bpmSeries, from: windowStart)
        guard
            Double(bpmWindow.count) >= 6 * bpmSampleRate,
            let spectral = SpectralEstimator.estimate(bpmWindow.map(\.value), sampleRate: bpmSampleRate)
        else {
            return PulseSnapshot(fingerState: fingerState, waveform: waveform)
        }

        state.red.beatDetector.expectedInterval = 60 / spectral.bpm
        state.green.beatDetector.expectedInterval = 60 / spectral.bpm

        let beats = channel.beats.filter { $0 >= windowStart }
        let score = QualityScorer.score(QualityInputs(
            snrDecibels: spectral.snrDecibels,
            perfusionIndex: state.latestPerfusion ?? 0,
            templateCorrelation: BeatTemplate.correlation(signal: filtered, beatTimes: beats, sampleRate: state.captureRate),
            usableFraction: ArtifactMask.usableFraction(bpmWindow, motion: state.motion),
            estimatorDisagreement: disagreement(bpm: spectral.bpm, beatTimes: beats)
        ))
        let quality = SignalQuality(score: score)
        return PulseSnapshot(
            fingerState: fingerState,
            bpm: quality == .poor ? nil : Int(spectral.bpm.rounded()),
            quality: quality,
            qualityScore: score,
            waveform: waveform
        )
    }

    private static func reselectChannelIfNeeded(_ state: inout State) {
        if let last = state.lastSelectionTime, state.latestTime - last < 2 { return }
        state.lastSelectionTime = state.latestTime

        let windowStart = state.latestTime - estimationWindow
        func snr(_ channel: ChannelState) -> Double {
            let values = Stats.suffix(of: channel.bpmSeries, from: windowStart).map(\.value)
            return SpectralEstimator.estimate(values, sampleRate: bpmSampleRate)?.snrDecibels ?? -.infinity
        }
        let redUsable = state.latestSaturation <= 0.3
        state.selected = redUsable && snr(state.red) > snr(state.green) ? .red : .green
    }

    static func perfusionIndex(_ pulse: [TimedValue]) -> Double {
        let values = pulse.map(\.value)
        return Stats.percentile(values, 0.95) - Stats.percentile(values, 0.05)
    }

    static func disagreement(bpm: Double, beatTimes: [TimeInterval]) -> Double? {
        let intervals = HRVCalculator.intervals(from: beatTimes).filter(HRVCalculator.validInterval.contains)
        guard intervals.count >= 3 else { return nil }
        return abs(bpm - 60 / Stats.median(intervals))
    }
}

extension PulseAnalysis.State {
    public var fingerState: FingerState { finger.state }

    /// Analyses the measuring phase with zero-phase filtering and windowed estimates.
    public func summarize() throws(PulseAnalysisError) -> PulseSummary {
        guard let start = measuringStart else { throw .unreliable }
        let channel = selected == .red ? red : green

        let bpmPhase = Stats.suffix(of: channel.bpmSeries, from: start)
        guard ArtifactMask.usableFraction(bpmPhase, motion: motion) >= 0.5 else { throw .unreliable }

        let estimates = windowedEstimates(bpmPhase)
        guard !estimates.isEmpty else { throw .unreliable }
        let bpm = Stats.median(estimates.map(\.bpm))

        let segments = Self.contiguousSegments(Stats.suffix(of: channel.normalized, from: start))
            .filter { ($0.last?.time ?? 0) - ($0.first?.time ?? 0) >= 4 }
            .map { segment in
                let filtered = BandPassFilter.zeroPhase(segment.map(\.value), sampleRate: captureRate)
                return zip(segment, filtered).map { TimedValue(time: $0.time, value: $1) }
            }
        let beats = segments.flatMap { segment in
            var detector = BeatDetector(sampleRate: captureRate, expectedInterval: 60 / bpm)
            return segment.compactMap { BeatDetector.process($0.value, at: $0.time, &detector) }
        }

        let intervals = HRVCalculator.intervals(from: beats)
        let mask = HRVCalculator.acceptanceMask(for: intervals)
        let accepted = zip(intervals, mask).filter(\.1).map(\.0)
        let pulse = segments.flatMap { $0 }

        let score = QualityScorer.score(QualityInputs(
            snrDecibels: Stats.median(estimates.map(\.snrDecibels)),
            perfusionIndex: PulseAnalysis.perfusionIndex(pulse),
            templateCorrelation: BeatTemplate.correlation(signal: pulse, beatTimes: beats, sampleRate: captureRate),
            usableFraction: ArtifactMask.usableFraction(bpmPhase, motion: motion),
            estimatorDisagreement: accepted.count >= 3 ? abs(bpm - 60 / Stats.median(accepted)) : nil
        ))

        return PulseSummary(
            bpm: Int(bpm.rounded()),
            quality: SignalQuality(score: score),
            qualityScore: score,
            hrv: HRVCalculator.compute(beatTimes: beats),
            beatIntervals: accepted,
            waveform: Self.excerpt(of: segments.max(by: { $0.count < $1.count }) ?? [], seconds: 5)
        )
    }

    private func windowedEstimates(_ series: [TimedValue]) -> [SpectralEstimate] {
        guard let first = series.first?.time, let last = series.last?.time else { return [] }
        let window = PulseAnalysis.estimationWindow
        let minimumCount = Int(0.9 * window * PulseAnalysis.bpmSampleRate)
        return stride(from: first, through: last - window, by: 1).compactMap { windowStart in
            let samples = series.filter { $0.time >= windowStart && $0.time < windowStart + window }
            guard samples.count >= minimumCount, ArtifactMask.usableFraction(samples, motion: motion) >= 0.5 else {
                return nil
            }
            return SpectralEstimator.estimate(samples.map(\.value), sampleRate: PulseAnalysis.bpmSampleRate)
        }
    }

    /// Splits wherever consecutive samples are more than 0.25 s apart, i.e. where the finger was lifted.
    private static func contiguousSegments(_ series: [TimedValue]) -> [[TimedValue]] {
        var segments: [[TimedValue]] = []
        for sample in series {
            if let last = segments.last?.last, sample.time - last.time <= 0.25 {
                segments[segments.count - 1].append(sample)
            } else {
                segments.append([sample])
            }
        }
        return segments
    }

    private static func excerpt(of segment: [TimedValue], seconds: TimeInterval) -> [Double] {
        guard let first = segment.first?.time, let last = segment.last?.time else { return [] }
        let middle = (first + last) / 2
        let values = segment.filter { abs($0.time - middle) <= seconds / 2 }.map(\.value)
        return Waveform.displayPoints(values, count: 100)
    }
}

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
