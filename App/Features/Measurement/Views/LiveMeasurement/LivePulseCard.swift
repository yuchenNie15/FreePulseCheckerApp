import DesignSystem
import SwiftUI

internal struct LivePulseCard: View {
    internal let waveform: [Double]
    internal let isLive: Bool
    internal let isCalibrating: Bool

    internal var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Live pulse").microLabelStyle()
                Spacer()
                if isLive {
                    HStack(spacing: 6) {
                        Text("Live").microLabelStyle(.accentStart)
                        Circle().fill(Color.accentStart).frame(width: 8, height: 8)
                    }
                }
            }
            WaveformView(points: waveform, lineWidth: isCalibrating ? 1.5 : 3)
                .opacity(isCalibrating ? 0.5 : 1)
                .frame(height: 90)
        }
        .card()
    }
}

internal struct LivePulseCard_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<(waveform: [Double], isLive: Bool, isCalibrating: Bool)> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Live", state: (MeasurementScreensPreviewFixtures.waveform, true, false)),
                .init(name: "Not live", state: (MeasurementScreensPreviewFixtures.waveform, false, false)),
                .init(name: "Calibrating", state: (MeasurementScreensPreviewFixtures.waveform, false, true)),
                .init(name: "Empty waveform", state: ([], true, false)),
            ],
            configure: { state in
                LivePulseCard(waveform: state.waveform, isLive: state.isLive, isCalibrating: state.isCalibrating)
                    .measurementComponentPreview()
            }
        )
    }
}
