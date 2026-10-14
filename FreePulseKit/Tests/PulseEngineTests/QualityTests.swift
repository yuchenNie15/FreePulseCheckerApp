import Foundation
import Testing
@testable import PulseEngine

@Suite struct QualityTests {
    @Test func idealInputsScoreOne() {
        #expect(QualityScorer.score(inputs()) == 1)
    }

    @Test func worstInputsScoreZero() {
        let worst = inputs(snr: -3, perfusion: 0.0001, correlation: 0.2, usable: 0.3, disagreement: 30)
        #expect(QualityScorer.score(worst) == 0)
    }

    @Test func missingBeatEstimateCapsTheScore() {
        #expect(abs(QualityScorer.score(inputs(disagreement: nil)) - 0.8) < 1e-9)
    }

    /** Every term except SNR is ideal, as when noise alone fills the band with plausible amplitude.

    Expected: the score is capped at 0.3, so the reading is Poor and no BPM is shown. */
    @Test func noDominantRhythmIsAlwaysPoor() {
        #expect(QualityScorer.score(inputs(snr: 1.5)) == 0.3)
    }

    @Test func scoresMapToQualityBands() {
        #expect(SignalQuality(score: 0.85) == .good)
        #expect(SignalQuality(score: 0.7) == .good)
        #expect(SignalQuality(score: 0.55) == .fair)
        #expect(SignalQuality(score: 0.39) == .poor)
    }

    @Test func motionMarksHalfASecondEitherSide() {
        var log = MotionLog()
        MotionLog.record(MotionSample(timestamp: 10, magnitude: 1.3), &log)
        MotionLog.record(MotionSample(timestamp: 11, magnitude: 1.01), &log)
        #expect(log.isStill(at: 9.4))
        #expect(!log.isStill(at: 9.6))
        #expect(!log.isStill(at: 10.4))
        #expect(log.isStill(at: 10.6))
    }

    @Test func amplitudeSpikesAreMaskedButASineIsNot() {
        var samples = sine(frequency: 1.2, sampleRate: 30, duration: 8).enumerated()
            .map { TimedValue(time: Double($0) / 30, value: $1) }
        #expect(ArtifactMask.usableFraction(samples, motion: MotionLog()) == 1)
        samples[100].value = 20
        let mask = ArtifactMask.usableMask(samples, motion: MotionLog())
        #expect(!mask[100])
        #expect(mask.filter { !$0 }.count == 1)
    }

    @Test func identicalBeatsCorrelatePerfectly() {
        let ppg = SyntheticPPG(intervals: Array(repeating: 0.8, count: 12))
        let signal = (0..<600).map { TimedValue(time: Double($0) / 60, value: ppg.pulse(at: Double($0) / 60)) }
        let correlation = BeatTemplate.correlation(signal: signal, beatTimes: ppg.beatTimes, sampleRate: 60)
        #expect(correlation > 0.99)
    }

    @Test func waveformIsDownsampledAndScaled() {
        let points = Waveform.displayPoints((0..<1000).map { Double($0) - 500 }, count: 100)
        #expect(points.count == 100)
        #expect(points.first == -1)
        #expect(points.allSatisfy { (-1...1).contains($0) })
    }

    private func inputs(
        snr: Double = 10,
        perfusion: Double = 0.01,
        correlation: Double = 0.95,
        usable: Double = 1,
        disagreement: Double? = 1
    ) -> QualityInputs {
        QualityInputs(
            snrDecibels: snr,
            perfusionIndex: perfusion,
            templateCorrelation: correlation,
            usableFraction: usable,
            estimatorDisagreement: disagreement
        )
    }
}
