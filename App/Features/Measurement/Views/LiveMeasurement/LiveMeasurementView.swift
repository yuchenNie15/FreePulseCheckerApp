import DesignSystem
import PulseEngine
import SwiftUI

internal struct LiveMeasurementView: View {
    internal let phase: MeasurementFeature.Phase
    internal let snapshot: PulseSnapshot
    internal let remainingSeconds: Int

    private var isCalibrating: Bool { phase == .calibrating }
    private var prompt: FingerPrompt? { FingerPrompt(snapshot.fingerState, isPaused: phase == .paused) }

    internal var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let prompt {
                    FingerPromptBanner(prompt: prompt)
                }
                LiveBPMRing(isCalibrating: isCalibrating, bpm: snapshot.bpm, remainingSeconds: remainingSeconds)
                    .frame(width: 280, height: 280)
                    .padding(.top, prompt == nil ? 24 : 0)
                if isCalibrating {
                    CalibratingCaption()
                }
                SignalQualityChip(quality: isCalibrating ? nil : snapshot.quality)
                LivePulseCard(waveform: snapshot.waveform, isLive: phase == .measuring, isCalibrating: isCalibrating)
                guidance
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.vertical, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private var guidance: some View {
        if !isCalibrating {
            VStack(spacing: 6) {
                Text("Keep your finger still").font(.headline).foregroundStyle(Color.textPrimary)
                Text("Breathe normally and stay relaxed").font(.subheadline).foregroundStyle(Color.textSecondary)
            }
        } else {
            Text("Keep your finger still").font(.subheadline).foregroundStyle(Color.textSecondary)
        }
    }
}

internal struct LiveMeasurementView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<(phase: MeasurementFeature.Phase, snapshot: PulseSnapshot, remainingSeconds: Int)> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Calibrating", state: (.calibrating, MeasurementScreensPreviewFixtures.snapshot(bpm: nil, quality: nil), 60)),
                .init(name: "Measuring good signal", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(), 42)),
                .init(name: "Measuring no BPM yet", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(bpm: nil, quality: nil), 55)),
                .init(name: "Measuring fair signal", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(quality: .fair), 42)),
                .init(name: "Measuring poor signal", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(quality: .poor), 42)),
                .init(name: "Paused finger lifted", state: (.paused, MeasurementScreensPreviewFixtures.snapshot(fingerState: .absent), 42)),
                .init(name: "Finger partial", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(fingerState: .partial), 42)),
                .init(name: "Finger too much pressure", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(fingerState: .tooMuchPressure), 42)),
                .init(name: "Finger saturated", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(fingerState: .saturated), 42)),
                .init(name: "Finger too dark", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(fingerState: .tooDark), 42)),
                .init(name: "Remaining 60", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(), 60)),
                .init(name: "Remaining 1", state: (.measuring, MeasurementScreensPreviewFixtures.snapshot(), 1)),
            ],
            configure: { state in
                LiveMeasurementView(phase: state.phase, snapshot: state.snapshot, remainingSeconds: state.remainingSeconds)
                    .measurementScreenPreview()
            }
        )
    }
}
