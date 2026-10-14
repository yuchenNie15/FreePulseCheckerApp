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
