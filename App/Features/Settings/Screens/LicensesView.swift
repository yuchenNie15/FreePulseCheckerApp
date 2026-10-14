import ComposableArchitecture
import DesignSystem
import SwiftUI

internal struct LicensesView: View {
    internal let licenses: [License]

    internal init(licenses: [License]) {
        self.licenses = licenses
    }

    internal var body: some View {
        List {
            Section {
                ForEach(licenses) { license in
                    NavigationLink(state: SettingsFeature.Path.State.license(license)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(license.name).font(.body).foregroundStyle(Color.textPrimary)
                            Text(license.kind).font(.footnote).foregroundStyle(Color.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .settingsRowBackground()
                }
            } footer: {
                SettingsSectionFooter("The signal-processing approach was informed by ClimbPulse.")
            }
        }
        .settingsListStyle()
        .navigationTitle("Open-source licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

internal struct LicensesView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<[License]> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "All", state: License.all),
                .init(name: "Short", state: [License.climbPulse, License.apache[0]]),
            ],
            configure: { licenses in
                NavigationStack { LicensesView(licenses: licenses) }
            }
        )
    }
}
