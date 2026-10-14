import SwiftUI

/// The glowing circular hero button on the Measure tab.
public struct StartButton: View {
    private static let beat: TimeInterval = 1.4

    private let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle().stroke(Color.accentStart.opacity(0.35), lineWidth: 2).frame(width: 196, height: 196)
                Circle()
                    .stroke(Color.accentStart, lineWidth: 4)
                    .frame(width: 176, height: 176)
                    .scaleEffect(isPulsing ? 1.35 : 1)
                    .opacity(isPulsing ? 0 : 0.6)
                    .animation(pulse(autoreverses: false), value: isPulsing)
                Circle()
                    .stroke(Color.accentStart.opacity(0.7), lineWidth: 6)
                    .frame(width: 176, height: 176)
                    .scaleEffect(isPulsing ? 1.05 : 1)
                    .animation(pulse(autoreverses: true), value: isPulsing)
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
        .onAppear { isPulsing = !reduceMotion }
        .onChange(of: reduceMotion) { _, reduceMotion in isPulsing = !reduceMotion }
    }

    /// The ripple runs one way per beat; the breathing ring goes out and back within the same beat.
    private func pulse(autoreverses: Bool) -> Animation? {
        guard isPulsing else { return nil }
        let duration = autoreverses ? Self.beat / 2 : Self.beat
        return .easeOut(duration: duration).repeatForever(autoreverses: autoreverses)
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
