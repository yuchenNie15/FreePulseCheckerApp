import Foundation

extension PulseAnalysis.State {
    public var fingerState: FingerState { finger.state }

    /// Analyses the measuring phase with zero-phase filtering and windowed estimates.
    public func summarize() throws(PulseAnalysisError) -> PulseSummary {
        guard let start = measuringStart else { throw .unreliable }
        let channel = selected == .red ? red : green

        let bpmPhase = Stats.suffix(of: channel.bpmSeries, from: start)
        guard ArtifactMask.usableFraction(bpmPhase, motion: motion) >= 0.5 else { throw .unreliable }

        let estimates = windowedEstimates(bpmPhase)
        guard !estimates.isEmpty else { throw .unreliable }
        let bpm = Stats.median(estimates.map(\.bpm))

        let segments = Self.contiguousSegments(Stats.suffix(of: channel.normalized, from: start))
            .filter { ($0.last?.time ?? 0) - ($0.first?.time ?? 0) >= 4 }
            .map { segment in
                let filtered = BandPassFilter.zeroPhase(segment.map(\.value), sampleRate: captureRate)
                return zip(segment, filtered).map { TimedValue(time: $0.time, value: $1) }
            }
        let beats = segments.flatMap { segment in
            var detector = BeatDetector(sampleRate: captureRate, expectedInterval: 60 / bpm)
            return segment.compactMap { BeatDetector.process($0.value, at: $0.time, &detector) }
        }

        let intervals = HRVCalculator.intervals(from: beats)
        let mask = HRVCalculator.acceptanceMask(for: intervals)
        let accepted = zip(intervals, mask).filter(\.1).map(\.0)
        let pulse = segments.flatMap { $0 }

        let score = QualityScorer.score(QualityInputs(
            snrDecibels: Stats.median(estimates.map(\.snrDecibels)),
            perfusionIndex: PulseAnalysis.perfusionIndex(pulse),
            templateCorrelation: BeatTemplate.correlation(signal: pulse, beatTimes: beats, sampleRate: captureRate),
            usableFraction: ArtifactMask.usableFraction(bpmPhase, motion: motion),
            estimatorDisagreement: accepted.count >= 3 ? abs(bpm - 60 / Stats.median(accepted)) : nil
        ))

        return PulseSummary(
            bpm: Int(bpm.rounded()),
            quality: SignalQuality(score: score),
            qualityScore: score,
            hrv: HRVCalculator.compute(beatTimes: beats),
            beatIntervals: accepted,
            waveform: Self.excerpt(of: segments.max(by: { $0.count < $1.count }) ?? [], seconds: 5)
        )
    }

    private func windowedEstimates(_ series: [TimedValue]) -> [SpectralEstimate] {
        guard let first = series.first?.time, let last = series.last?.time else { return [] }
        let window = PulseAnalysis.estimationWindow
        let minimumCount = Int(0.9 * window * PulseAnalysis.bpmSampleRate)
        return stride(from: first, through: last - window, by: 1).compactMap { windowStart in
            let samples = series.filter { $0.time >= windowStart && $0.time < windowStart + window }
            guard samples.count >= minimumCount, ArtifactMask.usableFraction(samples, motion: motion) >= 0.5 else {
                return nil
            }
            return SpectralEstimator.estimate(samples.map(\.value), sampleRate: PulseAnalysis.bpmSampleRate)
        }
    }

    /// Splits wherever consecutive samples are more than 0.25 s apart, i.e. where the finger was lifted.
    private static func contiguousSegments(_ series: [TimedValue]) -> [[TimedValue]] {
        var segments: [[TimedValue]] = []
        for sample in series {
            if let last = segments.last?.last, sample.time - last.time <= 0.25 {
                segments[segments.count - 1].append(sample)
            } else {
                segments.append([sample])
            }
        }
        return segments
    }

    private static func excerpt(of segment: [TimedValue], seconds: TimeInterval) -> [Double] {
        guard let first = segment.first?.time, let last = segment.last?.time else { return [] }
        let middle = (first + last) / 2
        let values = segment.filter { abs($0.time - middle) <= seconds / 2 }.map(\.value)
        return Waveform.displayPoints(values, count: 100)
    }
}
