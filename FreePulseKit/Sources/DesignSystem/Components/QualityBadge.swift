import PulseEngine
import SwiftUI

public struct QualityBadge: View {
    private let quality: SignalQuality
    private let prefix: String?

    public init(_ quality: SignalQuality, prefix: String? = nil) {
        self.quality = quality
        self.prefix = prefix
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle().fill(quality.color).frame(width: 8, height: 8)
            Text(prefix.map { "\($0) \(quality.title)" } ?? quality.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
    }
}

internal struct QualityBadge_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<(quality: SignalQuality, prefix: String?)> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Good", state: (.good, nil)),
                .init(name: "Fair", state: (.fair, nil)),
                .init(name: "Poor", state: (.poor, nil)),
                .init(name: "Good With Prefix", state: (.good, "Signal:")),
                .init(name: "Fair With Prefix", state: (.fair, "Signal:")),
                .init(name: "Poor With Prefix", state: (.poor, "Signal:")),
            ],
            configure: { state in
                QualityBadge(state.quality, prefix: state.prefix).padding().background(Color.background)
            }
        )
    }
}
