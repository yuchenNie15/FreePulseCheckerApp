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
