import DesignSystem
import SwiftUI

internal struct EmptyHistoryView: View {
    internal init() {}

    internal var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.fill")
                .font(.system(size: 34))
                .foregroundStyle(LinearGradient.accent)
                .frame(width: 76, height: 76)
                .background(Color.accentTint, in: .circle)
            Text("No readings yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textPrimary)
            Text("Your measurements will appear here.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(Metrics.screenMargin)
    }
}

internal struct EmptyHistoryView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<DynamicTypeSize> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Default", state: .large),
                .init(name: "Accessibility 3 text", state: .accessibility3),
            ],
            configure: { dynamicTypeSize in
                EmptyHistoryView()
                    .environment(\.dynamicTypeSize, dynamicTypeSize)
                    .frame(width: 390)
                    .background(Color.background)
            }
        )
    }
}
