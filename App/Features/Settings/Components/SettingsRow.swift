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

internal struct SettingsRow_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<SettingsRow> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "TitleOnly", state: SettingsRow(icon: "lock.fill", tileColor: Color(hex: 0x0A84FF), title: "On-device only")),
                .init(
                    name: "Subtitle",
                    state: SettingsRow(
                        icon: "doc.text",
                        tileColor: Color(hex: 0x636366),
                        title: "Open-source licenses",
                        subtitle: "Includes ClimbPulse (MIT)"
                    )
                ),
                .init(name: "Value", state: SettingsRow(icon: "timer", tileColor: .warning, title: "Duration", value: "60 s")),
                .init(
                    name: "ValueColor",
                    state: SettingsRow(
                        icon: "heart.fill",
                        iconColor: .accentStart,
                        tileColor: .white,
                        title: "Apple Health",
                        value: "Connected",
                        valueColor: .qualityGood
                    )
                ),
                .init(
                    name: "Chevron",
                    state: SettingsRow(
                        icon: "heart.fill",
                        iconColor: .accentStart,
                        tileColor: .white,
                        title: "Apple Health",
                        value: "Not connected",
                        showsChevron: true
                    )
                ),
                .init(
                    name: "LongValue",
                    state: SettingsRow(
                        icon: "hand.point.up.left.fill",
                        tileColor: .accentStart,
                        title: "Method",
                        value: "Fingertip on rear camera"
                    )
                ),
            ],
            configure: { row in
                row
                    .padding(.horizontal, 16)
                    .frame(width: 358)
                    .background(Color.surface)
            }
        )
    }
}
