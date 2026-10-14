import DesignSystem
import PulseEngine
import SwiftUI

internal struct SignalQualityChip: View {
    /// Nil shows the "Reading…" placeholder.
    internal let quality: SignalQuality?

    internal var body: some View {
        Group {
            if let quality {
                QualityBadge(quality, prefix: "Signal:")
            } else {
                HStack(spacing: 6) {
                    Circle().fill(Color.textSecondary).frame(width: 8, height: 8)
                    Text("Quality: Reading…")
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
