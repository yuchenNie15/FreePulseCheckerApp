import DesignSystem
import SwiftUI

internal struct MeasurementActionButtons: View {
    internal let primaryTitle: LocalizedStringKey
    internal let secondaryTitle: LocalizedStringKey
    internal let onPrimary: () -> Void
    internal let onSecondary: () -> Void

    internal var body: some View {
        VStack(spacing: 12) {
            Button(primaryTitle, action: onPrimary)
                .buttonStyle(.primary)
            Button(action: onSecondary) {
                Text(secondaryTitle).foregroundStyle(Color.accentEnd)
            }
            .buttonStyle(.secondary)
        }
        .padding(.horizontal, Metrics.screenMargin)
        .padding(.bottom, 8)
    }
}
