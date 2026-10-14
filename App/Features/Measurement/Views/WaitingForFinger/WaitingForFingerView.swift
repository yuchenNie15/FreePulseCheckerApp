import DesignSystem
import PulseEngine
import SwiftUI

internal struct WaitingForFingerView: View {
    internal let fingerState: FingerState

    private var prompt: FingerPrompt? { FingerPrompt(fingerState, isPaused: false) }

    internal var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)
            FingerOnCameraIllustration()
                .frame(width: 300, height: 400)
            Spacer(minLength: 16)
            Text("Cover the rear camera and flash with your fingertip")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("Rest it gently — don't press. Keep your hand steady and stay seated.")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            Group {
                if let prompt {
                    FingerPromptBanner(prompt: prompt)
                } else {
                    WaitingPill()
                }
            }
            .padding(.top, 28)
            Spacer(minLength: 16)
            Text("Not a medical device")
                .font(.footnote)
                .foregroundStyle(Color.textTertiary)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, Metrics.screenMargin + 8)
    }
}
