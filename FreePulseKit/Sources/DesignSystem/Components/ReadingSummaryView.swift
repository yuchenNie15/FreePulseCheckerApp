import Models
import SwiftUI

/// The result layout from the mockups: hero BPM, HRV card, quality and waveform thumbnail.
public struct ReadingSummaryView: View {
    private let reading: PulseReading

    public init(reading: PulseReading) {
        self.reading = reading
    }

    public var body: some View {
        VStack(spacing: Metrics.cardSpacing) {
            VStack(spacing: 4) {
                Text("\(reading.bpm)")
                    .font(.heroNumeral)
                    .foregroundStyle(LinearGradient.accent)
                Text("BPM").font(.title3.weight(.semibold)).foregroundStyle(Color.textSecondary)
                QualityBadge(reading.quality, prefix: "Signal:")
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 14) {
                Text("Heart rate variability").microLabelStyle()
                if let rmssd = reading.rmssd, let sdnn = reading.sdnn {
                    HStack(spacing: 0) {
                        metric("RMSSD", value: rmssd)
                        Divider().overlay(Color.separator).frame(height: 44)
                        metric("SDNN", value: sdnn).padding(.leading, 20)
                    }
                } else {
                    Text("HRV unavailable — try to stay still")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .card()

            if !reading.waveform.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pulse").microLabelStyle()
                    WaveformView(points: reading.waveform, lineWidth: 2.5).frame(height: 70)
                }
                .card()
            }
        }
    }

    private func metric(_ title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.footnote.weight(.semibold)).foregroundStyle(Color.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(value.rounded()))").font(.cardNumeral).foregroundStyle(Color.textPrimary)
                Text("ms").font(.subheadline).foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

internal struct ReadingSummaryView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<PulseReading> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "HRV Available", state: PreviewFixtures.reading()),
                .init(name: "RMSSD Only", state: PreviewFixtures.reading(sdnn: nil)),
                .init(name: "HRV Unavailable", state: PreviewFixtures.reading(rmssd: nil, sdnn: nil)),
                .init(name: "No Waveform", state: PreviewFixtures.reading(waveform: [])),
                .init(name: "Fair Quality", state: PreviewFixtures.reading(bpm: 88, rmssd: 28, sdnn: 35, quality: .fair)),
                .init(name: "Poor Quality", state: PreviewFixtures.reading(bpm: 64, rmssd: 19, sdnn: 24, quality: .poor)),
                .init(name: "Three Digit BPM", state: PreviewFixtures.reading(bpm: 142, rmssd: 120, sdnn: 135)),
            ],
            configure: { reading in
                ReadingSummaryView(reading: reading)
                    .padding(Metrics.screenMargin)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .screenBackground()
            }
        )
    }
}
