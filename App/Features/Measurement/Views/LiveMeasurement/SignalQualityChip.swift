import DesignSystem
import PulseEngine
import SwiftUI

internal struct SignalQualityChip: View {
    /// Nil shows the "Checking accuracy…" placeholder.
    internal let quality: SignalQuality?

    internal var body: some View {
        Group {
            if let quality {
                QualityBadge(quality)
            } else {
                HStack(spacing: 6) {
                    Circle().fill(Color.textSecondary).frame(width: 8, height: 8)
                    Text("Checking accuracy…")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.surfaceElevated, in: .capsule)
    }
}

internal struct SignalQualityChip_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<SignalQuality?> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Reading", state: nil),
                .init(name: "Good", state: .good),
                .init(name: "Fair", state: .fair),
                .init(name: "Poor", state: .poor),
            ],
            configure: { quality in
                SignalQualityChip(quality: quality)
                    .measurementComponentPreview()
            }
        )
    }
}
