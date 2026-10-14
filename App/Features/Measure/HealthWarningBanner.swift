import DesignSystem
import SwiftUI

internal struct HealthWarningBanner: View {
    internal let message: String
    internal let onDismiss: () -> Void

    internal var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.warning)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.textSecondary)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(16)
        .background(Color.surface, in: .rect(cornerRadius: Metrics.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Metrics.cardRadius).strokeBorder(Color.warning.opacity(0.45)))
    }
}

internal struct HealthWarningBanner_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<String> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Short message", state: "Saved on this iPhone. Apple Health access is off."),
                .init(
                    name: "Long message",
                    state: "Saved on this iPhone, but Apple Health didn't accept it. Check Health access in Settings › Privacy & Security › Health › Free Pulse Check, then try again."
                ),
            ],
            configure: { message in HealthWarningBanner(message: message, onDismiss: {}).padding().background(Color.background) }
        )
    }
}
