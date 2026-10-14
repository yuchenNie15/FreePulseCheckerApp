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
