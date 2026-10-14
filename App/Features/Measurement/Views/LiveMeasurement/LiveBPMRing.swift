import DesignSystem
import SwiftUI

internal struct LiveBPMRing: View {
    internal let isCalibrating: Bool
    internal let bpm: Int?
    internal let remainingSeconds: Int

    internal var body: some View {
        ZStack {
            if isCalibrating {
                IndeterminateRing()
            } else {
                ProgressRing(progress: Double(MeasurementFeature.duration - remainingSeconds) / Double(MeasurementFeature.duration))
            }
            VStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(LinearGradient.accent)
                    .opacity(isCalibrating ? 0.7 : 1)
                if let bpm, !isCalibrating {
                    Text("\(bpm)")
                        .font(.heroNumeral)
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                } else {
                    Text("– –")
                        .font(.heroNumeral)
                        .foregroundStyle(Color.textTertiary)
                }
                Text("BPM").font(.title3.weight(.semibold)).foregroundStyle(Color.textSecondary)
                if !isCalibrating {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Self.countdown(remainingSeconds))
                            .font(.title2.weight(.bold).monospacedDigit())
                            .foregroundStyle(Color.textPrimary)
                        Text("left").font(.subheadline).foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private static func countdown(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
