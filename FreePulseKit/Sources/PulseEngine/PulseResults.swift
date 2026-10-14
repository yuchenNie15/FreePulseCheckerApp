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
