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

internal struct ViewModifiers_Previews: PreviewProvider {
    internal enum Sample {
        case card
        case cardCustomPadding
        case glow
        case microLabel
        case microLabelCustomColor
    }

    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Sample> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Card", state: .card),
                .init(name: "Card Custom Padding", state: .cardCustomPadding),
                .init(name: "Glow", state: .glow),
                .init(name: "Micro Label", state: .microLabel),
                .init(name: "Micro Label Custom Color", state: .microLabelCustomColor),
            ],
            configure: { sample in
                content(for: sample)
                    .frame(width: PreviewFixtures.componentWidth)
                    .padding()
                    .background(Color.background)
            }
        )
    }

    @ViewBuilder
    private static func content(for sample: Sample) -> some View {
        switch sample {
        case .card:
            Text("Card content").foregroundStyle(Color.textPrimary).card()
        case .cardCustomPadding:
            Text("Card content").foregroundStyle(Color.textPrimary).card(padding: 8)
        case .glow:
            Image(systemName: "heart.fill")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient.accent)
                .glow()
                .padding(24)
        case .microLabel:
            Text("Heart rate variability").microLabelStyle()
        case .microLabelCustomColor:
            Text("Heart rate variability").microLabelStyle(.accentEnd)
        }
    }
}
