import DesignSystem
import SwiftUI

internal struct CameraDeniedView: View {
    internal let onOpenSettings: () -> Void
    internal let onDismiss: () -> Void

    internal var body: some View {
        VStack(spacing: 0) {
            HStack {
                CloseButton(action: onDismiss)
                Spacer()
            }
            .padding(.top, 8)
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "camera.slash")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(Color.accentEnd)
                        .frame(width: 128, height: 128)
                        .background(Color.accentTint, in: .circle)
                        .padding(10)
                        .overlay(Circle().stroke(Color.accentEnd.opacity(0.6), lineWidth: 2))
                        .glow(radius: 18, opacity: 0.35)
                        .padding(.top, 60)
                    Text("Camera access needed")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Free Pulse Check reads your pulse from tiny color changes in your fingertip, seen through the rear camera and flash. Nothing is recorded or uploaded.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("To enable").microLabelStyle()
                        Text("Settings › Free Pulse Check › Camera")
                            .font(.body)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .card()
                    .padding(.top, 12)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 12) {
                Button("Open Settings", action: onOpenSettings)
                    .buttonStyle(.primary)
                Button("Not Now", action: onDismiss)
                    .font(.headline)
                    .foregroundStyle(Color.accentEnd)
                    .frame(minHeight: 44)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Metrics.screenMargin)
        .screenBackground()
        .preferredColorScheme(.dark)
    }
}
