import Foundation
import Testing
@testable import PulseEngine

@Suite struct HRVCalculatorTests {
    @Test func steadyRhythmHasNoVariability() throws {
        let result = try #require(HRVCalculator.compute(beatTimes: beats(Array(repeating: 1.0, count: 30))))
        #expect(result.rmssd == 0)
        #expect(result.sdnn == 0)
        #expect(result.meanInterval == 1000)
        #expect(result.beatCount == 31)
    }

    @Test func alternatingIntervalsGiveKnownRMSSDAndSDNN() throws {
        let intervals = (0..<30).map { $0.isMultiple(of: 2) ? 0.9 : 1.0 }
        let result = try #require(HRVCalculator.compute(beatTimes: beats(intervals)))
        #expect(abs(result.rmssd - 100) < 0.001)
        #expect(abs(result.sdnn - sdnnMilliseconds(intervals)) < 0.001)
    }

    @Test func missedBeatIsRejected() throws {
        var intervals = Array(repeating: 1.0, count: 30)
        intervals[15] = 2.0
        let result = try #require(HRVCalculator.compute(beatTimes: beats(intervals)))
        #expect(result.rmssd == 0)
    }

    @Test func extraBeatIsRejected() throws {
        var intervals = Array(repeating: 1.0, count: 30)
        intervals.replaceSubrange(15...15, with: [0.45, 0.55])
        let result = try #require(HRVCalculator.compute(beatTimes: beats(intervals)))
        #expect(result.rmssd == 0)
        #expect(result.sdnn == 0)
    }

    @Test func recordingsShorterThan25SecondsAreNotReported() {
        #expect(HRVCalculator.compute(beatTimes: beats(Array(repeating: 1.0, count: 20))) == nil)
    }

    @Test func mostlyRejectedIntervalsAreNotReported() {
        let intervals = (0..<40).map { $0.isMultiple(of: 3) ? 2.0 : 1.0 }
        #expect(HRVCalculator.compute(beatTimes: beats(intervals)) == nil)
    }

    private func beats(_ intervals: [Double]) -> [TimeInterval] {
        intervals.reduce(into: [0.0]) { times, interval in times.append(times.last! + interval) }
    }
}
