import Accelerate

internal enum Stats {
    internal static func mean(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : vDSP.mean(values)
    }

    internal static func standardDeviation(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return vDSP.meanSquare(vDSP.add(-mean(values), values)).squareRoot()
    }

    internal static func sampleStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let n = Double(values.count)
        return standardDeviation(values) * (n / (n - 1)).squareRoot()
    }

    internal static func coefficientOfVariation(_ values: [Double]) -> Double {
        let mean = mean(values)
        return mean == 0 ? .infinity : standardDeviation(values) / mean
    }

    internal static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    /// Nearest-rank percentile, with `fraction` in 0...1.
    internal static func percentile(_ values: [Double], _ fraction: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let index = Int((fraction * Double(sorted.count - 1)).rounded())
        return sorted[min(max(index, 0), sorted.count - 1)]
    }

    internal static func pearson(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, a.count > 1 else { return 0 }
        let centeredA = vDSP.add(-mean(a), a)
        let centeredB = vDSP.add(-mean(b), b)
        let denominator = (vDSP.dot(centeredA, centeredA) * vDSP.dot(centeredB, centeredB)).squareRoot()
        return denominator == 0 ? 0 : vDSP.dot(centeredA, centeredB) / denominator
    }

    /// Index of the first element of `series` whose time is at or after `time`.
    internal static func firstIndex(in series: [TimedValue], atOrAfter time: TimeInterval) -> Int {
        var low = 0
        var high = series.count
        while low < high {
            let middle = (low + high) / 2
            if series[middle].time < time {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low
    }

    internal static func suffix(of series: [TimedValue], from time: TimeInterval) -> [TimedValue] {
        Array(series[firstIndex(in: series, atOrAfter: time)...])
    }
}
