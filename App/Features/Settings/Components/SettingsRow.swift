import DesignSystem
import SwiftUI

internal struct SettingsRow: View {
    internal let icon: String
    internal var iconColor: Color = .white
    internal let tileColor: Color
    internal let title: String
    internal var subtitle: String?
    internal var value: String?
    internal var valueColor: Color = .textSecondary
    internal var showsChevron = false

    internal var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 30, height: 30)
                .background(tileColor, in: .rect(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(Color.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(Color.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if let value {
                Text(value).font(.body).foregroundStyle(valueColor).multilineTextAlignment(.trailing)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
