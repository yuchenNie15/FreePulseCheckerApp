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
