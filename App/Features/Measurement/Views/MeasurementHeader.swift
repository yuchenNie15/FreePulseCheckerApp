import DesignSystem
import SwiftUI

internal struct MeasurementHeader: View {
    internal let phase: MeasurementFeature.Phase
    internal let onClose: () -> Void

    internal var body: some View {
        ZStack {
            Text(title).font(.headline).foregroundStyle(Color.textPrimary)
            HStack {
                CloseButton(action: onClose)
                Spacer()
            }
        }
        .padding(.horizontal, Metrics.screenMargin)
        .padding(.top, 8)
    }

    private var title: String {
        switch phase {
        case .preparing, .waitingForFinger: "Measure"
        case .calibrating, .measuring, .paused: "Measuring"
        case .result: "Result"
        case .failed: ""
        }
    }
}
