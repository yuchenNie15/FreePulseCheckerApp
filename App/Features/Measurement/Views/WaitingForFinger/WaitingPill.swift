import DesignSystem
import SwiftUI

internal struct WaitingPill: View {
    internal var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.qualityFair)
                .frame(width: 12, height: 12)
                .padding(5)
                .background(Color.qualityFair.opacity(0.25), in: .circle)
            Text("Waiting for finger")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
        .background(Color.surfaceElevated, in: .capsule)
        .overlay(Capsule().strokeBorder(Color.separator))
    }
}

internal struct WaitingPill_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Void> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Default", state: ()),
            ],
            configure: {
                WaitingPill().padding().background(Color.background)
            }
        )
    }
}
