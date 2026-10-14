import DesignSystem
import SwiftUI

internal struct FingerPromptBanner: View {
    internal let prompt: FingerPrompt

    internal var body: some View {
        HStack(spacing: 16) {
            Image(systemName: prompt.symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(prompt.color)
                .frame(width: 48, height: 48)
                .background(prompt.color.opacity(0.18), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(prompt.title).font(.headline).foregroundStyle(Color.textPrimary)
                Text(prompt.subtitle).font(.subheadline).foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.surface, in: .rect(cornerRadius: Metrics.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Metrics.cardRadius).strokeBorder(prompt.color.opacity(0.45)))
        .accessibilityElement(children: .combine)
    }
}

internal struct FingerPromptBanner_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<FingerPrompt> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Partial", state: .partial),
                .init(name: "Pressure", state: .pressure),
                .init(name: "Saturated", state: .saturated),
                .init(name: "Too Dark", state: .tooDark),
                .init(name: "Lifted", state: .lifted),
            ],
            configure: { prompt in
                FingerPromptBanner(prompt: prompt)
                    .padding()
                    .frame(width: 390)
                    .background(Color.background)
            }
        )
    }
}
