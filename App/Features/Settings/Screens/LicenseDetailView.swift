import DesignSystem
import SwiftUI

internal struct LicenseDetailView: View {
    internal let license: License

    internal init(license: License) {
        self.license = license
    }

    internal var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let note = license.note {
                    Text(note).font(.subheadline).foregroundStyle(Color.textSecondary)
                }
                Text(license.text)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .textSelection(.enabled)
            }
            .card(padding: 16)
            .padding(Metrics.screenMargin)
        }
        .screenBackground()
        .navigationTitle(license.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

internal struct LicenseDetailView_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<License> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "MIT", state: License.pointFree[0]),
                .init(name: "Apache", state: License.apache[0]),
                .init(name: "Note", state: License.climbPulse),
                .init(
                    name: "LongTitle",
                    state: License(
                        id: "long-title",
                        name: "The Composable Architecture Navigation Extensions",
                        kind: "MIT",
                        note: nil,
                        text: License.mitText(copyright: "Copyright (c) 2020 Point-Free, Inc.")
                    )
                ),
            ],
            configure: { license in
                NavigationStack { LicenseDetailView(license: license) }
            }
        )
    }
}
