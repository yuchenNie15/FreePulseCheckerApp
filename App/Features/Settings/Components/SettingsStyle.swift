import DesignSystem
import SwiftUI

extension View {
    internal func settingsListStyle() -> some View {
        self
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .screenBackground()
            .tint(Color.accentEnd)
    }

    internal func settingsRowBackground() -> some View {
        self
            .listRowBackground(Color.surface)
            .listRowSeparatorTint(Color.separator)
    }
}
