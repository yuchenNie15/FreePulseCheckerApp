import DesignSystem
import SwiftUI

internal struct PrivacySection: View {
    internal init() {}

    internal var body: some View {
        Section {
            SettingsRow(icon: "lock.fill", tileColor: Color(hex: 0x0A84FF), title: "On-device only")
                .settingsRowBackground()
        } header: {
            SettingsSectionHeader("Privacy")
        } footer: {
            SettingsSectionFooter("No account and no network. Readings stay on this iPhone unless you save them to Apple Health.")
        }
    }
}

internal struct PrivacySection_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<Void> {
        AppPreviewSnapshots(
            configurations: [.init(name: "Default", state: ())],
            configure: { _ in
                List { PrivacySection() }
                    .settingsListStyle()
                    .frame(width: 390, height: 220)
            }
        )
    }
}
