import Foundation
import PulseEngine

extension PulseReading {
    /// Readings for SwiftUI previews, newest first, relative to `now`.
    public static func previewReadings(now: Date = Date()) -> [PulseReading] {
        let waveform = (0..<100).map { index -> Double in
            let phase = Double(index).truncatingRemainder(dividingBy: 20) / 20
            return exp(-pow((phase - 0.2) / 0.06, 2)) + 0.35 * exp(-pow((phase - 0.5) / 0.08, 2))
        }
        func reading(_ hoursAgo: Double, bpm: Int, rmssd: Double?, sdnn: Double?, quality: SignalQuality) -> PulseReading {
            PulseReading(
                id: UUID(),
                date: now.addingTimeInterval(-hoursAgo * 3600),
                bpm: bpm,
                rmssd: rmssd,
                sdnn: sdnn,
                quality: quality,
                qualityScore: quality == .good ? 0.86 : quality == .fair ? 0.55 : 0.3,
                beatIntervals: [],
                waveform: waveform,
                savedToHealth: quality != .poor
            )
        }
        return [
            reading(0.2, bpm: 72, rmssd: 42, sdnn: 51, quality: .good),
            reading(16, bpm: 68, rmssd: 38, sdnn: 47, quality: .fair),
            reading(50, bpm: 81, rmssd: 29, sdnn: 33, quality: .poor),
            reading(75, bpm: 64, rmssd: nil, sdnn: nil, quality: .fair),
            reading(120, bpm: 70, rmssd: 45, sdnn: 55, quality: .good),
        ]
    }
}
