import SwiftUI

/// The glowing circular hero button on the Measure tab.
public struct StartButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle().stroke(Color.accentStart.opacity(0.35), lineWidth: 2).frame(width: 196, height: 196)
                Circle().stroke(Color.accentStart.opacity(0.7), lineWidth: 6).frame(width: 176, height: 176)
                Circle()
                    .fill(LinearGradient.accent)
                    .frame(width: 148, height: 148)
                    .shadow(color: .accentStart.opacity(0.7), radius: 24)
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill").font(.system(size: 52))
                    Text("START").font(.system(size: 15, weight: .bold)).tracking(2)
                }
                .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start Measurement")
    }
}

internal struct StartButton_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Void> {
        AppPreviewSnapshots(
            configurations: [.init(name: "Default", state: ())],
            configure: { StartButton(action: {}).padding(32).background(Color.background) }
        )
    }
}
