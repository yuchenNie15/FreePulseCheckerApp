import SwiftUI

extension View {
    public func card(padding: CGFloat = Metrics.cardPadding) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surface, in: .rect(cornerRadius: Metrics.cardRadius))
    }

    /// The accent gradient blurred behind the view.
    public func glow(radius: CGFloat = 14, opacity: Double = 0.6) -> some View {
        background {
            self.foregroundStyle(LinearGradient.accent).blur(radius: radius).opacity(opacity)
        }
    }

    /// Uppercase 11 pt bold with 1 pt tracking, as used for section labels.
    public func microLabelStyle(_ color: Color = .textTertiary) -> some View {
        self.font(.microLabel).tracking(1).textCase(.uppercase).foregroundStyle(color)
    }

    public func screenBackground() -> some View {
        background(Color.background.ignoresSafeArea())
    }
}
