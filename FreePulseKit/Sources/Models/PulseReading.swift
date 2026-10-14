import Foundation
import PulseEngine

public struct PulseReading: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var date: Date
    public var bpm: Int
    /// Milliseconds; nil when too few clean beats were found.
    public var rmssd: Double?
    /// Milliseconds; nil when too few clean beats were found.
    public var sdnn: Double?
    public var quality: SignalQuality
    public var qualityScore: Double
    /// Accepted interbeat intervals in seconds, kept for future HRV features.
    public var beatIntervals: [Double]
    /// 100 points scaled to -1...1.
    public var waveform: [Double]
    public var savedToHealth: Bool

    public init(
        id: UUID,
        date: Date,
        bpm: Int,
        rmssd: Double?,
        sdnn: Double?,
        quality: SignalQuality,
        qualityScore: Double,
        beatIntervals: [Double],
        waveform: [Double],
        savedToHealth: Bool = false
    ) {
        self.id = id
        self.date = date
        self.bpm = bpm
        self.rmssd = rmssd
        self.sdnn = sdnn
        self.quality = quality
        self.qualityScore = qualityScore
        self.beatIntervals = beatIntervals
        self.waveform = waveform
        self.savedToHealth = savedToHealth
    }

    public init(id: UUID, date: Date, summary: PulseSummary) {
        self.init(
            id: id,
            date: date,
            bpm: summary.bpm,
            rmssd: summary.hrv?.rmssd,
            sdnn: summary.hrv?.sdnn,
            quality: summary.quality,
            qualityScore: summary.qualityScore,
            beatIntervals: summary.beatIntervals,
            waveform: summary.waveform
        )
    }
}
