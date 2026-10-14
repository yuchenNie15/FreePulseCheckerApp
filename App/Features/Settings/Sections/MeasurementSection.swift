import DesignSystem
import SwiftUI

internal struct MeasurementSection: View {
    internal init() {}

    internal var body: some View {
        Section {
            SettingsRow(icon: "timer", tileColor: .warning, title: "Duration", value: "60 s")
                .settingsRowBackground()
            SettingsRow(icon: "hand.point.up.left.fill", tileColor: .accentStart, title: "Method", value: "Fingertip on rear camera")
                .settingsRowBackground()
        } header: {
            SettingsSectionHeader("Measurement")
        } footer: {
            SettingsSectionFooter("Fixed length keeps HRV readings comparable.")
        }
    }
}
