import Foundation
@testable import PulseEngine

/// Deterministic SplitMix64 so synthetic signals are identical on every run.
internal struct SeededGenerator {
    private var state: UInt64

    internal init(seed: UInt64) {
        state = seed
    }

    internal static func next(_ generator: inout SeededGenerator) -> UInt64 {
        generator.state &+= 0x9E37_79B9_7F4A_7C15
        var z = generator.state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    internal static func uniform(in range: ClosedRange<Double>, _ generator: inout SeededGenerator) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * Double(next(&generator) >> 11) * 0x1p-53
    }

    internal static func gaussian(standardDeviation: Double, _ generator: inout SeededGenerator) -> Double {
        let u1 = max(uniform(in: 0...1, &generator), .ulpOfOne)
        let u2 = uniform(in: 0...1, &generator)
        return standardDeviation * (-2 * log(u1)).squareRoot() * cos(2 * Double.pi * u2)
    }
}

/** A fingertip pulse wave with known beat times.
- Each beat is a systolic Gaussian 0.12 s after the beat plus a dicrotic wave at 35% amplitude later in the cycle.
- Brightness falls as blood volume rises, as it does through a finger under the torch. */
internal struct SyntheticPPG {
    internal let beatTimes: [TimeInterval]

    internal init(intervals: [Double], start: TimeInterval = 0.3) {
        var time = start
        var beats = [start]
        for interval in intervals {
            time += interval
            beats.append(time)
        }
        beatTimes = beats
    }

    /// Intervals with a 0.25 Hz respiratory swing of ±`variability` seconds plus Gaussian jitter.
    internal static func intervals(bpm: Double, duration: TimeInterval, variability: Double = 0.04, seed: UInt64 = 1) -> [Double] {
        var generator = SeededGenerator(seed: seed)
        let base = 60 / bpm
        var intervals: [Double] = []
        var elapsed = 0.0
        while elapsed < duration {
            let interval = base + variability * sin(2 * Double.pi * 0.25 * elapsed) + SeededGenerator.gaussian(standardDeviation: 0.006, &generator)
            intervals.append(interval)
            elapsed += interval
        }
        return intervals
    }

    internal func pulse(at time: TimeInterval) -> Double {
        var value = 0.0
        for (index, beat) in beatTimes.enumerated() where beat > time - 2 && beat < time + 0.5 {
            let interval = index + 1 < beatTimes.count ? beatTimes[index + 1] - beat : 0.8
            value += Self.gaussian(time, center: beat + 0.12, width: 0.05)
            value += 0.35 * Self.gaussian(time, center: beat + 0.12 + 0.3 * interval, width: 0.07)
        }
        return value
    }

    /// Camera frames at `rate` Hz with ±3 ms timestamp jitter; `noise` is the brightness noise standard deviation.
    internal func frames(rate: Double, duration: TimeInterval, noise: Double = 0.05, jitter: Double = 0.003, seed: UInt64 = 2) -> [PPGFrame] {
        var generator = SeededGenerator(seed: seed)
        return (0..<Int(duration * rate)).map { index in
            let time = Double(index) / rate + SeededGenerator.uniform(in: -jitter...jitter, &generator)
            let pulse = pulse(at: time)
            let red = 200 * (1 - 0.01 * pulse) + SeededGenerator.gaussian(standardDeviation: noise, &generator)
            let green = 70 * (1 - 0.02 * pulse) + SeededGenerator.gaussian(standardDeviation: noise, &generator)
            return PPGFrame(timestamp: time, cells: Self.uniformCells(red: red, green: green))
        }
    }

    internal func intervals(from start: TimeInterval, through end: TimeInterval) -> [Double] {
        HRVCalculator.intervals(from: beatTimes.filter { $0 >= start && $0 <= end })
    }

    internal static func uniformCells(red: Double, green: Double, blue: Double = 20, saturated: Double = 0) -> [CellStats] {
        Array(repeating: CellStats(meanRed: red, meanGreen: green, meanBlue: blue, saturatedFraction: saturated), count: 64)
    }

    private static func gaussian(_ x: Double, center: Double, width: Double) -> Double {
        exp(-0.5 * pow((x - center) / width, 2))
    }
}

internal func rmssdMilliseconds(_ intervals: [Double]) -> Double {
    let differences = zip(intervals.dropFirst(), intervals).map { $0 - $1 }
    return (differences.map { $0 * $0 }.reduce(0, +) / Double(differences.count)).squareRoot() * 1000
}

internal func sdnnMilliseconds(_ intervals: [Double]) -> Double {
    let mean = intervals.reduce(0, +) / Double(intervals.count)
    let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count - 1)
    return variance.squareRoot() * 1000
}

internal func sine(frequency: Double, sampleRate: Double, duration: TimeInterval, amplitude: Double = 1) -> [Double] {
    (0..<Int(duration * sampleRate)).map { amplitude * sin(2 * Double.pi * frequency * Double($0) / sampleRate) }
}
