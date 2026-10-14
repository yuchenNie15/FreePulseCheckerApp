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

internal struct MeasurementActionButtons_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<(primary: LocalizedStringKey, secondary: LocalizedStringKey)> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Save Discard", state: (primary: "Save", secondary: "Discard")),
                .init(name: "Try Again Close", state: (primary: "Try Again", secondary: "Close")),
            ],
            configure: { titles in
                MeasurementActionButtons(primaryTitle: titles.primary, secondaryTitle: titles.secondary) {} onSecondary: {}
                    .padding(.top, 8)
                    .frame(width: 390)
                    .background(Color.background)
            }
        )
    }
}
