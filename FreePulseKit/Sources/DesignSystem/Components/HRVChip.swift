import SwiftUI

/// A capsule chip showing RMSSD, or a dash when HRV is unavailable.
public struct HRVChip: View {
    private let rmssd: Double?

    public init(rmssd: Double?) {
        self.rmssd = rmssd
    }

    public var body: some View {
        Text(rmssd.map { "RMSSD \(Int($0.rounded())) ms" } ?? "HRV —")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.accentEnd)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accentTint, in: .capsule)
    }
}

internal struct HRVChip_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Double?> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "With RMSSD", state: 42),
                .init(name: "Unavailable", state: nil),
            ],
            configure: { rmssd in HRVChip(rmssd: rmssd).padding().background(Color.background) }
        )
    }
}
