import DesignSystem
import SwiftUI

internal struct ShimmerBar: View {
    @State private var offset: CGFloat = -1

    internal var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.surfaceElevated)
                .overlay {
                    LinearGradient(colors: [.clear, .accentEnd, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: proxy.size.width * 0.4)
                        .offset(x: offset * proxy.size.width * 0.7)
                }
                .clipShape(.capsule)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                offset = 1
            }
        }
    }
}

internal struct ShimmerBar_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Void> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Default", state: ()),
            ],
            configure: { _ in
                ShimmerBar()
                    .frame(height: 6)
                    .measurementComponentPreview()
            }
        )
    }
}
