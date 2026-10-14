import DesignSystem
import SwiftUI

internal struct SettingsVersionFooter: View {
    /// Nil until loaded; the version line is omitted.
    internal let appVersion: String?

    internal init(appVersion: String?) {
        self.appVersion = appVersion
    }

    internal var body: some View {
        VStack(spacing: 6) {
            if let appVersion {
                Text("Free Pulse Check \(appVersion)")
            }
            Text("Free. No ads. No subscriptions.")
        }
        .font(.footnote)
        .foregroundStyle(Color.textSecondary)
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
    }
}
