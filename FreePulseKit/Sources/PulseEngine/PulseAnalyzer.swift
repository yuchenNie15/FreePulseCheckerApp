import ComposableArchitecture

/** The signal-processing work behind `PulseAnalysis`, as a dependency.
- Live: `PulseAnalysis.ingest` and `PulseAnalysis.State.summarize()`.
- Feature tests override it to script snapshots and summaries without synthesising camera frames. */
public struct PulseAnalyzer: Sendable {
    public var ingest: @Sendable (_ frame: PPGFrame, _ state: inout PulseAnalysis.State) -> Void
    public var summarize: @Sendable (_ state: PulseAnalysis.State) throws -> PulseSummary

    public init(
        ingest: @escaping @Sendable (_ frame: PPGFrame, _ state: inout PulseAnalysis.State) -> Void,
        summarize: @escaping @Sendable (_ state: PulseAnalysis.State) throws -> PulseSummary
    ) {
        self.ingest = ingest
        self.summarize = summarize
    }
}

extension PulseAnalyzer: DependencyKey {
    public static let liveValue = PulseAnalyzer(
        ingest: { frame, state in PulseAnalysis.ingest(frame, &state) },
        summarize: { state in try state.summarize() }
    )

    public static let testValue = PulseAnalyzer(
        ingest: { _, _ in reportIssue("Unimplemented: PulseAnalyzer.ingest") },
        summarize: { _ in
            reportIssue("Unimplemented: PulseAnalyzer.summarize")
            throw PulseAnalysisError.unreliable
        }
    )
}

extension DependencyValues {
    public var pulseAnalyzer: PulseAnalyzer {
        get { self[PulseAnalyzer.self] }
        set { self[PulseAnalyzer.self] = newValue }
    }
}
