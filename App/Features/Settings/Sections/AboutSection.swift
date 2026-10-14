import ComposableArchitecture
import DesignSystem
import SwiftUI

internal struct AboutSection: View {
    internal init() {}

    internal var body: some View {
        Section {
            NavigationLink(state: SettingsFeature.Path.State.disclaimer) {
                SettingsRow(icon: "info", tileColor: Color(hex: 0x5E5CE6), title: "Disclaimer", value: "Not a medical device")
            }
            .settingsRowBackground()
            NavigationLink(state: SettingsFeature.Path.State.licenses) {
                SettingsRow(
                    icon: "doc.text",
                    tileColor: Color(hex: 0x636366),
                    title: "Open-source licenses",
                    subtitle: "Includes ClimbPulse (MIT)"
                )
            }
            .settingsRowBackground()
        } header: {
            SettingsSectionHeader("About")
        }
    }
}
