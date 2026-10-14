import DesignSystem
import SwiftUI

internal struct DisclaimerView: View {
    internal init() {}

    internal var body: some View {
        ScrollView {
            Text(
                "Free Pulse Check is a wellness tool, not a medical device. It doesn't diagnose, treat or prevent any condition. If you have concerns about your heart, talk to a doctor."
            )
            .font(.body)
            .foregroundStyle(Color.textPrimary)
            .card()
            .padding(Metrics.screenMargin)
        }
        .screenBackground()
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
