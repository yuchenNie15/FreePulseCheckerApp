import DesignSystem
import SwiftUI

internal enum FailureTip {
    case moved
    case lifted
}

internal struct FailureTipRow: View {
    internal let tip: FailureTip

    internal var body: some View {
        HStack(spacing: 16) {
            Image(systemName: tip == .moved ? "arrow.left.and.right" : "arrow.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.qualityFair)
                .frame(width: 48, height: 48)
                .background(Color.qualityFair.opacity(0.18), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(tip == .moved ? "You moved too much" : "Your finger lifted off the camera")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Text(tip == .moved ? "Rest your hand on a table" : "Keep light, steady contact")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

internal struct FailureTipRow_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<FailureTip> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Moved", state: .moved),
                .init(name: "Lifted", state: .lifted),
            ],
            configure: { tip in
                FailureTipRow(tip: tip)
                    .measurementComponentPreview()
            }
        )
    }
}
