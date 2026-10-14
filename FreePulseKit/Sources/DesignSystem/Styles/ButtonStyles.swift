import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(label: configuration.label, isPressed: configuration.isPressed)
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        SecondaryButtonBody(label: configuration.label, isPressed: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    public static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

/// The rendering of `PrimaryButtonStyle`, separate so the pressed state can be previewed.
internal struct PrimaryButtonBody<Label: View>: View {
    internal let label: Label
    internal let isPressed: Bool

    internal var body: some View {
        label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(LinearGradient.accentHorizontal, in: .rect(cornerRadius: Metrics.buttonRadius))
            .opacity(isPressed ? 0.8 : 1)
    }
}

/// The rendering of `SecondaryButtonStyle`, separate so the pressed state can be previewed.
internal struct SecondaryButtonBody<Label: View>: View {
    internal let label: Label
    internal let isPressed: Bool

    internal var body: some View {
        label
            .font(.headline)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.surfaceElevated, in: .rect(cornerRadius: Metrics.buttonRadius))
            .opacity(isPressed ? 0.8 : 1)
    }
}

internal struct PrimaryButtonStyle_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Bool> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Normal", state: false),
                .init(name: "Pressed", state: true),
            ],
            configure: { isPressed in
                PrimaryButtonBody(label: Text("Start Measurement"), isPressed: isPressed)
                    .frame(width: PreviewFixtures.componentWidth)
                    .padding()
                    .background(Color.background)
            }
        )
    }
}

internal struct SecondaryButtonStyle_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Bool> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Normal", state: false),
                .init(name: "Pressed", state: true),
            ],
            configure: { isPressed in
                SecondaryButtonBody(label: Text("Done"), isPressed: isPressed)
                    .frame(width: PreviewFixtures.componentWidth)
                    .padding()
                    .background(Color.background)
            }
        )
    }
}
