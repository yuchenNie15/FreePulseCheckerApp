import DesignSystem
import HealthKitClient
import SwiftUI

internal struct HealthSection: View {
    /// Nil until the first refresh; the row is disabled and shows no status.
    internal let access: HealthAccess?
    internal let onTap: () -> Void

    internal init(access: HealthAccess?, onTap: @escaping () -> Void) {
        self.access = access
        self.onTap = onTap
    }

    internal var body: some View {
        Section {
            Button(action: onTap) {
                SettingsRow(
                    icon: "heart.fill",
                    iconColor: .accentStart,
                    tileColor: .white,
                    title: "Apple Health",
                    value: access?.statusText,
                    valueColor: access == .authorized ? .qualityGood : .textSecondary,
                    showsChevron: access?.isTappable == true
                )
            }
            .disabled(access?.isTappable != true)
            .settingsRowBackground()
        } header: {
            SettingsSectionHeader("Apple Health")
        } footer: {
            SettingsSectionFooter("Heart rate and HRV (SDNN) are written to Apple Health when you save a reading.")
        }
    }
}
