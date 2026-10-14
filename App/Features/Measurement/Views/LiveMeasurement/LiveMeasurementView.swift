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
