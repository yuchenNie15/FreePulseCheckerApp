import DesignSystem
import SwiftUI

internal struct HistorySectionHeader: View {
    internal let title: String

    internal init(title: String) {
        self.title = title
    }

    internal var body: some View {
        Text(title).microLabelStyle()
    }
}
