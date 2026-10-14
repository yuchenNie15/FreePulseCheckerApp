import Foundation
import Testing
@testable import PulseEngine

@Suite struct FilterTests {
    @Test(arguments: [1.0, 1.5, 2.5])
    func bandPassKeepsHeartRateFrequencies(frequency: Double) {
        #expect(settledAmplitude(frequency: frequency) > 0.8)
    }

    @Test(arguments: [0.1, 10.0])
    func bandPassRejectsDriftAndFlicker(frequency: Double) {
        #expect(settledAmplitude(frequency: frequency) < 0.2)
    }

    @Test func zeroPhaseFilteringKeepsPeaksInPlace() {
        let input = sine(frequency: 1.2, sampleRate: 60, duration: 20)
        let output = BandPassFilter.zeroPhase(input, sampleRate: 60)
        let middle = 700..<750
        let inputPeak = middle.max(by: { input[$0] < input[$1] })
        let outputPeak = middle.max(by: { output[$0] < output[$1] })
        #expect(inputPeak == outputPeak)
    }

    @Test func movingMeanAveragesTheMostRecentWindow() {
        var mean = MovingMean(windowCount: 3)
        let results = [3.0, 6, 9, 12].map { MovingMean.push($0, &mean) }
        #expect(results == [3, 4.5, 6, 9])
    }

    @Test func resamplerInterpolatesOntoAFixedGrid() {
        var resampler = UniformResampler(rate: 10)
        var output = UniformResampler.push(TimedValue(time: 0, value: 0), &resampler)
        output += UniformResampler.push(TimedValue(time: 0.25, value: 2.5), &resampler)
        #expect(output.map(\.time).map { ($0 * 100).rounded() } == [0, 10, 20])
        #expect(output.map(\.value).map { ($0 * 100).rounded() / 100 } == [0, 1, 2])
    }

    private func settledAmplitude(frequency: Double) -> Double {
        var filter = BandPassFilter(sampleRate: 30)
        let output = sine(frequency: frequency, sampleRate: 30, duration: 20).map { BandPassFilter.process($0, &filter) }
        return output.suffix(300).map(abs).max() ?? 0
    }
}
