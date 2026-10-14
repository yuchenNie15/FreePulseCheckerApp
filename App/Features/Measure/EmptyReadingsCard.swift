import DesignSystem
import SwiftUI

internal struct EmptyReadingsCard: View {
    internal var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Image(systemName: "heart")
                    .font(.system(size: 46, weight: .regular))
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 18, weight: .semibold))
                    .offset(y: -2)
            }
            .foregroundStyle(Color.accentEnd)
            .frame(width: 96, height: 96)
            .background(Color.accentTint, in: .circle)
            Text("No measurements yet")
                .font(.title3.bold())
                .foregroundStyle(Color.textPrimary)
            Text("Your readings will appear here. Tap Start Measurement and rest your fingertip on the rear camera.")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .card()
    }
}

internal struct EmptyReadingsCard_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Void> {
        AppPreviewSnapshots(
            configurations: [.init(name: "Default", state: ())],
            configure: { EmptyReadingsCard().padding().background(Color.background) }
        )
    }
}
