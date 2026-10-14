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

internal struct LiveBPMRing_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<(isCalibrating: Bool, bpm: Int?, remainingSeconds: Int)> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Calibrating", state: (true, nil, 60)),
                .init(name: "No BPM", state: (false, nil, 55)),
                .init(name: "BPM 74 remaining 60", state: (false, 74, 60)),
                .init(name: "BPM 74 remaining 30", state: (false, 74, 30)),
                .init(name: "BPM 74 remaining 1", state: (false, 74, 1)),
                .init(name: "Three-digit BPM", state: (false, 142, 30)),
            ],
            configure: { state in
                LiveBPMRing(isCalibrating: state.isCalibrating, bpm: state.bpm, remainingSeconds: state.remainingSeconds)
                    .frame(width: 280, height: 280)
                    .measurementComponentPreview(width: 280)
            }
        )
    }
}
