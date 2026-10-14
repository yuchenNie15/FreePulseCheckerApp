import DesignSystem
import SwiftUI

internal struct MeasureStartCard: View {
    internal let onStart: () -> Void

    internal var body: some View {
        VStack(spacing: 18) {
            StartButton(action: onStart)
                .padding(.top, 8)
            VStack(spacing: 6) {
                Text("Start Measurement")
                    .font(.title2.bold())
                    .foregroundStyle(Color.textPrimary)
                Text("60 seconds · finger on rear camera")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .card(padding: 24)
    }
}

internal struct MeasureStartCard_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Void> {
        AppPreviewSnapshots(
            configurations: [.init(name: "Default", state: ())],
            configure: { MeasureStartCard(onStart: {}).padding().background(Color.background) }
        )
    }
}
