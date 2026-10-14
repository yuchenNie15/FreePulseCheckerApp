import SwiftUI

/// Draws -1...1 points left to right as a smooth pulse line.
public struct WaveformShape: Shape {
    private let points: [Double]

    public init(points: [Double]) {
        self.points = points
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let step = rect.width / CGFloat(points.count - 1)
        for (index, value) in points.enumerated() {
            let point = CGPoint(x: CGFloat(index) * step, y: rect.midY - CGFloat(value) * rect.height / 2)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        return path
    }
}

public struct WaveformView: View {
    private let points: [Double]
    private let lineWidth: CGFloat

    public init(points: [Double], lineWidth: CGFloat = 3) {
        self.points = points
        self.lineWidth = lineWidth
    }

    public var body: some View {
        WaveformShape(points: points)
            .stroke(LinearGradient.accentHorizontal, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .shadow(color: .accentStart.opacity(0.6), radius: 6)
    }
}
