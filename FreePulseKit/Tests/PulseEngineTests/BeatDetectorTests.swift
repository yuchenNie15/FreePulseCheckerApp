import Foundation
import Testing
@testable import PulseEngine

@Suite struct BeatDetectorTests {
    /// A clean 60 Hz pulse wave with respiratory variability and a dicrotic wave after every beat.
    ///
    /// Expected: one detection per beat after the 1 s warm-up, none on the dicrotic wave, and detected
    /// intervals within 3 ms of the true intervals.
    @Test(arguments: [50.0, 75, 110, 160])
    func detectsEveryBeatWithAccurateTiming(bpm: Double) {
        let ppg = SyntheticPPG(intervals: SyntheticPPG.intervals(bpm: bpm, duration: 30))
        var detector = BeatDetector(sampleRate: 60, expectedInterval: 60 / bpm)
        let beats = (0..<(30 * 60)).compactMap { index -> TimeInterval? in
            let time = Double(index) / 60
            return BeatDetector.process(ppg.pulse(at: time), at: time, &detector)
        }

        let expected = ppg.beatTimes.filter { $0 > 1.2 && $0 < 29 }
        let detected = beats.filter { $0 > 1.2 && $0 < 29 }
        #expect(detected.count == expected.count)

        let detectedIntervals = HRVCalculator.intervals(from: detected)
        let trueIntervals = HRVCalculator.intervals(from: expected)
        let worstError = zip(detectedIntervals, trueIntervals).map { abs($0 - $1) }.max() ?? .infinity
        #expect(worstError < 0.003)
    }
}
