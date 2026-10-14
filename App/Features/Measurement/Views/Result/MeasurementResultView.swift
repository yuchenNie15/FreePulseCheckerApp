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

internal struct MeasurementResultView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<(reading: PulseReading, saveToHealth: Bool)> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Good with HRV health on", state: (MeasurementScreensPreviewFixtures.goodReading, true)),
                .init(name: "Fair without HRV health off", state: (MeasurementScreensPreviewFixtures.fairReadingWithoutHRV, false)),
                .init(name: "Poor", state: (MeasurementScreensPreviewFixtures.poorReading, true)),
                .init(name: "Three-digit BPM", state: (MeasurementScreensPreviewFixtures.threeDigitReading, true)),
            ],
            configure: { state in
                MeasurementResultView(reading: state.reading, saveToHealth: .constant(state.saveToHealth), onSave: {}, onDiscard: {})
                    .measurementScreenPreview()
            }
        )
    }
}
