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
