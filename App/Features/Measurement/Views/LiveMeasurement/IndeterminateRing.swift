import DesignSystem
import SwiftUI

internal struct IndeterminateRing: View {
    @State private var isRotating = false

    internal var body: some View {
        ZStack {
            Circle().stroke(Color.surfaceElevated, lineWidth: 16)
            Circle()
                .trim(from: 0, to: 0.22)
                .stroke(
                    AngularGradient(colors: [.clear, .accentEnd], center: .center, startAngle: .zero, endAngle: .degrees(80)),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(isRotating ? 270 : -90))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                isRotating = true
            }
        }
    }
}

internal struct IndeterminateRing_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Void> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Default", state: ()),
            ],
            configure: { _ in
                IndeterminateRing()
                    .frame(width: 280, height: 280)
                    .measurementComponentPreview(width: 280)
            }
        )
    }
}
