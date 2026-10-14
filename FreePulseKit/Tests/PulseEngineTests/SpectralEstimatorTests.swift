import Foundation
import Testing
@testable import PulseEngine

@Suite struct SpectralEstimatorTests {
    @Test(arguments: [48.0, 72, 118, 175])
    func findsTheHeartRateOfASine(bpm: Double) throws {
        let signal = sine(frequency: bpm / 60, sampleRate: 30, duration: 8)
        let estimate = try #require(SpectralEstimator.estimate(signal, sampleRate: 30))
        #expect(abs(estimate.bpm - bpm) < 0.5)
        #expect(estimate.snrDecibels > 10)
    }

    /// The second harmonic carries more power than the fundamental, as with a pronounced dicrotic notch.
    ///
    /// Expected: the estimate reports the fundamental, not double it.
    @Test func prefersTheFundamentalOverAStrongerHarmonic() throws {
        let fundamental = sine(frequency: 1.2, sampleRate: 30, duration: 8)
        let harmonic = sine(frequency: 2.4, sampleRate: 30, duration: 8, amplitude: 1.2)
        let estimate = try #require(SpectralEstimator.estimate(zip(fundamental, harmonic).map(+), sampleRate: 30))
        #expect(abs(estimate.bpm - 72) < 0.5)
    }

    @Test func whiteNoiseHasNegativeSNR() throws {
        var generator = SeededGenerator(seed: 7)
        let noise = (0..<240).map { _ in SeededGenerator.gaussian(standardDeviation: 1, &generator) }
        let estimate = try #require(SpectralEstimator.estimate(noise, sampleRate: 30))
        #expect(estimate.snrDecibels < 0)
    }

    @Test func signalsShorterThanFourSecondsAreRejected() {
        #expect(SpectralEstimator.estimate(sine(frequency: 1.2, sampleRate: 30, duration: 3), sampleRate: 30) == nil)
    }
}
