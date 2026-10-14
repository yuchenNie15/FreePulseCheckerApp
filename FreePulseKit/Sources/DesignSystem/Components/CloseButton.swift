import SwiftUI

/// The round close button used at the top-left of full-screen covers.
public struct CloseButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(Color.surfaceElevated, in: .circle)
        }
        .accessibilityLabel("Close")
    }
}
