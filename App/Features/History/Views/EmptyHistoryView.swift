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
