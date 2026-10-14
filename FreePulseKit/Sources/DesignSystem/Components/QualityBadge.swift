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
