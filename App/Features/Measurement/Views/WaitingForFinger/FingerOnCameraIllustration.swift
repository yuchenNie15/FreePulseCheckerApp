import DesignSystem
import SwiftUI

internal struct FingerOnCameraIllustration: View {
    internal var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.surface)
                .strokeBorder(Color.separator, lineWidth: 1.5)
                .frame(width: 200, height: 330)
                .offset(x: 6, y: 6)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.accentStart.opacity(0.45), .clear], center: .center, startRadius: 4, endRadius: 70))
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.separator, lineWidth: 1.5)
                    .frame(width: 96, height: 96)
                Circle()
                    .stroke(Color.accentEnd, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
            }
            .frame(width: 140, height: 140)
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: 0xF2C2A8), Color(hex: 0xD99478)], startPoint: .top, endPoint: .bottom))
                .frame(width: 280, height: 92)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: 0xF8D4C2))
                        .frame(width: 58, height: 52)
                        .padding(.leading, 14)
                }
                .rotationEffect(.degrees(33), anchor: .leading)
                .offset(x: 26, y: 24)
        }
        .frame(width: 300, height: 400, alignment: .topLeading)
        .clipped()
        .accessibilityHidden(true)
    }
}
