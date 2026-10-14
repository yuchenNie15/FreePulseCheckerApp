import DesignSystem
import SwiftUI

internal struct CalibratingCaption: View {
    internal var body: some View {
        VStack(spacing: 8) {
            Text("Hold still…")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text("Calibrating to your signal")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
            ShimmerBar()
                .frame(height: 6)
                .padding(.horizontal, 40)
                .padding(.top, 12)
        }
    }
}
