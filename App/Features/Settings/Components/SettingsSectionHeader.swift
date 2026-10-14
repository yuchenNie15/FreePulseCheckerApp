import DesignSystem
import SwiftUI

internal struct SettingsSectionHeader: View {
    private let title: String

    internal init(_ title: String) {
        self.title = title
    }

    internal var body: some View {
        Text(title).microLabelStyle(.textSecondary)
    }
}

internal struct SettingsSectionHeader_Previews: PreviewProvider {
    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<String> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Short", state: "About"),
                .init(name: "MultiLine", state: "Measurement settings that apply to every new reading you take"),
            ],
            configure: { title in
                SettingsSectionHeader(title)
                    .padding(16)
                    .frame(width: 390, alignment: .leading)
                    .screenBackground()
            }
        )
    }
}
