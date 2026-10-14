import ComposableArchitecture
import Foundation

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
