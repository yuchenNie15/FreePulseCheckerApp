import DesignSystem
import SwiftUI

internal struct SaveToHealthRow: View {
    @Binding internal var isOn: Bool

    internal var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "heart.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.accentStart)
                .frame(width: 44, height: 44)
                .background(Color.white, in: .rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("Save to Apple Health").font(.headline).foregroundStyle(Color.textPrimary)
                Text("Heart rate and HRV (SDNN)").font(.subheadline).foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 8)
            Toggle("Save to Apple Health", isOn: $isOn)
                .labelsHidden()
                .tint(.qualityGood)
        }
        .card(padding: 18)
    }
}
