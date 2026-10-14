import Foundation
import PulseEngine

extension PulseSourceClient {
    /** A synthetic fingertip pulse delivered in real time, for the simulator and previews.
    - Parameter bpm: Mean heart rate; intervals swing ±40 ms with a 0.25 Hz respiratory rhythm.
    - Parameter fingerDelay: Seconds of bare-lens frames before the finger arrives.
    - Parameter speed: Playback rate; values above 1 deliver frames faster than real time. */
    public static func simulated(bpm: Double, fingerDelay: TimeInterval = 1.5, speed: Double = 1) -> PulseSourceClient {
        let captureRate = 60.0
        return PulseSourceClient(
            captureRate: { captureRate },
            events: {
                AsyncThrowingStream { continuation in
                    let task = Task {
                        var waveform = SimulatedWaveform(bpm: bpm)
                        var index = 0
                        let framesPerTick = Int(captureRate * PulseAnalysis.snapshotInterval)
                        while !Task.isCancelled {
                            for _ in 0..<framesPerTick {
                                let time = Double(index) / captureRate
                                let frame = time < fingerDelay
                                    ? SimulatedWaveform.bareLensFrame(at: time)
                                    : SimulatedWaveform.fingerFrame(at: time, &waveform)
                                continuation.yield(.frame(frame))
                                if index.isMultiple(of: 2) {
                                    continuation.yield(.motion(MotionSample(timestamp: time, magnitude: 1)))
                                }
                                index += 1
                            }
                            try? await Task.sleep(for: .seconds(PulseAnalysis.snapshotInterval / speed))
                        }
                        continuation.finish()
                    }
                    continuation.onTermination = { _ in task.cancel() }
                }
            }
        )
    }
}

private struct SimulatedWaveform: Sendable {
    private let baseInterval: Double
    private var beats: [TimeInterval] = [0]

    init(bpm: Double) {
        baseInterval = 60 / bpm
    }

    static func bareLensFrame(at time: TimeInterval) -> PPGFrame {
        PPGFrame(timestamp: time, cells: cells(red: 120, green: 110, blue: 100))
    }

    static func fingerFrame(at time: TimeInterval, _ waveform: inout SimulatedWaveform) -> PPGFrame {
        while let last = waveform.beats.last, last < time + 0.5 {
            let swing = 0.04 * sin(2 * Double.pi * 0.25 * last)
            waveform.beats.append(last + waveform.baseInterval + swing)
        }
        waveform.beats.removeAll { $0 < time - 2 }

        let pulse = waveform.beats.reduce(0.0) { sum, beat in
            sum + gaussian(time, center: beat + 0.12, width: 0.05)
                + 0.35 * gaussian(time, center: beat + 0.12 + 0.3 * waveform.baseInterval, width: 0.07)
        }
        let noise = Double.random(in: -0.1...0.1)
        return PPGFrame(
            timestamp: time,
            cells: cells(red: 200 * (1 - 0.01 * pulse) + noise, green: 70 * (1 - 0.02 * pulse) + noise, blue: 20)
        )
    }

    private static func cells(red: Double, green: Double, blue: Double) -> [CellStats] {
        Array(repeating: CellStats(meanRed: red, meanGreen: green, meanBlue: blue), count: 64)
    }

    private static func gaussian(_ x: Double, center: Double, width: Double) -> Double {
        exp(-0.5 * pow((x - center) / width, 2))
    }
}
