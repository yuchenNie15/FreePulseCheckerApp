import DesignSystem
import SwiftUI

internal struct MeasurementFailedView: View {
    internal let reason: MeasurementFeature.FailureReason
    internal let onTryAgain: () -> Void
    internal let onClose: () -> Void

    internal var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.qualityFair)
                        .frame(width: 96, height: 96)
                        .background(Color.qualityFair.opacity(0.3), in: .circle)
                        .padding(18)
                        .background(Color.qualityFair.opacity(0.12), in: .circle)
                        .padding(.top, 40)
                    Text("Couldn't get a reliable reading")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(explanation)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                    if !tips.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                if index > 0 {
                                    Divider().overlay(Color.separator).padding(.leading, 64)
                                }
                                FailureTipRow(tip: tip)
                            }
                        }
                        .background(Color.surface, in: .rect(cornerRadius: Metrics.cardRadius))
                    }
                }
                .padding(.horizontal, Metrics.screenMargin)
            }
            .scrollBounceBehavior(.basedOnSize)
            MeasurementActionButtons(
                primaryTitle: "Try Again",
                secondaryTitle: "Close",
                onPrimary: onTryAgain,
                onSecondary: onClose
            )
        }
    }

    private var explanation: String {
        switch reason {
        case .unreliable: "Nothing was saved. This usually happens when:"
        case .fingerLifted: "Nothing was saved. Your finger was off the camera for more than 10 seconds."
        case .cameraUnavailable: "Nothing was saved. The camera or flash couldn't be started. Close other camera apps and try again."
        case .overheated: "Nothing was saved. Your iPhone is too warm. Let it cool down and try again."
        case .interrupted: "Nothing was saved. The measurement stopped when the app left the screen."
        }
    }

    private var tips: [FailureTip] {
        switch reason {
        case .unreliable: [.moved, .lifted]
        case .fingerLifted: [.lifted]
        case .cameraUnavailable, .overheated, .interrupted: []
        }
    }
}

internal struct MeasurementFailedView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<MeasurementFeature.FailureReason> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Unreliable", state: .unreliable),
                .init(name: "Finger lifted", state: .fingerLifted),
                .init(name: "Camera unavailable", state: .cameraUnavailable),
                .init(name: "Overheated", state: .overheated),
                .init(name: "Interrupted", state: .interrupted),
            ],
            configure: { reason in
                MeasurementFailedView(reason: reason, onTryAgain: {}, onClose: {})
                    .measurementScreenPreview()
            }
        )
    }
}
