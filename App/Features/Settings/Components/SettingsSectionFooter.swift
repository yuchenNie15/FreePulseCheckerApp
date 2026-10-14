import DesignSystem
import SwiftUI

internal struct SettingsSectionFooter: View {
    private let text: String

    internal init(_ text: String) {
        self.text = text
    }

    internal var body: some View {
        Text(text).font(.footnote).foregroundStyle(Color.textSecondary)
    }
}

internal struct SettingsSectionFooter_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<String> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Short", state: "Fixed length keeps HRV readings comparable."),
                .init(
                    name: "MultiLine",
                    state: "No account and no network. Readings stay on this iPhone unless you save them to Apple Health."
                ),
            ],
            configure: { text in
                SettingsSectionFooter(text)
                    .padding(16)
                    .frame(width: 390, alignment: .leading)
                    .screenBackground()
            }
        )
    }
}
