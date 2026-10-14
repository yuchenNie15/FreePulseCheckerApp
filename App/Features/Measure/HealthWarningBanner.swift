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
