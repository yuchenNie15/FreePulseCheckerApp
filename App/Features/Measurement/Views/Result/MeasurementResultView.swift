import DesignSystem
import Models
import SwiftUI

internal struct MeasurementResultView: View {
    internal let reading: PulseReading
    @Binding internal var saveToHealth: Bool
    internal let onSave: () -> Void
    internal let onDiscard: () -> Void

    internal var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Metrics.cardSpacing) {
                    ReadingSummaryView(reading: reading)
                    SaveToHealthRow(isOn: $saveToHealth)
                    Text("Not a medical device. Don't use for diagnosis.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, Metrics.screenMargin)
                .padding(.vertical, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            MeasurementActionButtons(
                primaryTitle: "Save",
                secondaryTitle: "Discard",
                onPrimary: onSave,
                onSecondary: onDiscard
            )
        }
    }
}
