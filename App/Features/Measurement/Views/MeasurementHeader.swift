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

internal struct MeasurementHeader_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<MeasurementFeature.Phase> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Preparing", state: .preparing),
                .init(name: "Waiting For Finger", state: .waitingForFinger),
                .init(name: "Calibrating", state: .calibrating),
                .init(name: "Measuring", state: .measuring),
                .init(name: "Paused", state: .paused),
                .init(name: "Result", state: .result(MeasurementFlowPreviewFixtures.reading)),
                .init(name: "Failed", state: .failed(.unreliable)),
            ],
            configure: { phase in
                MeasurementHeader(phase: phase) {}
                    .padding(.bottom, 8)
                    .frame(width: 390)
                    .background(Color.background)
            }
        )
    }
}
