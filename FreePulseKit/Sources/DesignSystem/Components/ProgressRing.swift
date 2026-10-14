import SwiftUI

/// A gradient ring filled clockwise from the top; `progress` is 0...1.
public struct ProgressRing: View {
    private let progress: Double
    private let lineWidth: CGFloat

    public init(progress: Double, lineWidth: CGFloat = 16) {
        self.progress = progress
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle().stroke(Color.surfaceElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(LinearGradient.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: .accentStart.opacity(0.6), radius: 10)
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

internal struct ProgressRing_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Double> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Empty", state: 0),
                .init(name: "Partial", state: 0.3),
                .init(name: "Full", state: 1),
            ],
            configure: { progress in
                ProgressRing(progress: progress).frame(width: 200, height: 200).padding(32).background(Color.background)
            }
        )
    }
}
