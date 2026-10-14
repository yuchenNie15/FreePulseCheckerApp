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

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(LinearGradient.accentHorizontal, in: .rect(cornerRadius: Metrics.buttonRadius))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.surfaceElevated, in: .rect(cornerRadius: Metrics.buttonRadius))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    public static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

/// The round close button used at the top-left of full-screen covers.
public struct CloseButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(Color.surfaceElevated, in: .circle)
        }
        .accessibilityLabel("Close")
    }
}
