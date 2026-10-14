import ComposableArchitecture
import DesignSystem
import Models
import PulseEngine
import SwiftUI

internal struct MeasurementView: View {
    @Bindable private var store: StoreOf<MeasurementFeature>
    @Environment(\.scenePhase) private var scenePhase

    internal init(store: StoreOf<MeasurementFeature>) {
        self.store = store
    }

    internal var body: some View {
        VStack(spacing: 0) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .screenBackground()
        .preferredColorScheme(.dark)
        .task { await store.send(.task).finish() }
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.scenePhaseChanged(newPhase))
        }
        .alert($store.scope(\.alert, action: \.alert))
    }

    private var header: some View {
        ZStack {
            Text(title).font(.headline).foregroundStyle(Color.textPrimary)
            HStack {
                CloseButton { store.send(.closeTapped) }
                Spacer()
            }
        }
        .padding(.horizontal, Metrics.screenMargin)
        .padding(.top, 8)
    }

    private var title: String {
        switch store.phase {
        case .preparing, .waitingForFinger: "Measure"
        case .calibrating, .measuring, .paused: "Measuring"
        case .result: "Result"
        case .failed: ""
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .preparing, .waitingForFinger:
            WaitingForFingerView(prompt: FingerPrompt(store.analysis.snapshot.fingerState, isPaused: false))
        case .calibrating, .measuring, .paused:
            LiveMeasurementView(
                phase: store.phase,
                snapshot: store.analysis.snapshot,
                remainingSeconds: store.remainingSeconds
            )
        case let .result(reading):
            ResultView(reading: reading, saveToHealth: $store.saveToHealth) {
                store.send(.saveTapped)
            } onDiscard: {
                store.send(.discardTapped)
            }
        case let .failed(reason):
            FailedView(reason: reason) {
                store.send(.tryAgainTapped)
            } onClose: {
                store.send(.closeTapped)
            }
        }
    }
}

private struct WaitingForFingerView: View {
    internal let prompt: FingerPrompt?

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

private struct FingerOnCameraIllustration: View {
    internal var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.surface)
                .strokeBorder(Color.separator, lineWidth: 1.5)
                .frame(width: 200, height: 330)
                .offset(x: 6, y: 6)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.accentStart.opacity(0.45), .clear], center: .center, startRadius: 4, endRadius: 70))
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.separator, lineWidth: 1.5)
                    .frame(width: 96, height: 96)
                Circle()
                    .stroke(Color.accentEnd, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
            }
            .frame(width: 140, height: 140)
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: 0xF2C2A8), Color(hex: 0xD99478)], startPoint: .top, endPoint: .bottom))
                .frame(width: 280, height: 92)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: 0xF8D4C2))
                        .frame(width: 58, height: 52)
                        .padding(.leading, 14)
                }
                .rotationEffect(.degrees(33), anchor: .leading)
                .offset(x: 26, y: 24)
        }
        .frame(width: 300, height: 400, alignment: .topLeading)
        .clipped()
        .accessibilityHidden(true)
    }
}

private struct WaitingPill: View {
    internal var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.qualityFair)
                .frame(width: 12, height: 12)
                .padding(5)
                .background(Color.qualityFair.opacity(0.25), in: .circle)
            Text("Waiting for finger")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 24)
        .frame(height: 56)
        .background(Color.surfaceElevated, in: .capsule)
        .overlay(Capsule().strokeBorder(Color.separator))
    }
}

private enum FingerPrompt: Equatable {
    case partial
    case pressure
    case saturated
    case tooDark
    case lifted

    internal init?(_ fingerState: FingerState, isPaused: Bool) {
        switch fingerState {
        case .partial: self = .partial
        case .tooMuchPressure: self = .pressure
        case .saturated: self = .saturated
        case .tooDark: self = .tooDark
        case .absent where isPaused: self = .lifted
        case .absent, .present: return nil
        }
    }

    internal var title: String {
        switch self {
        case .partial: "Cover the whole lens"
        case .pressure: "Press a little lighter"
        case .saturated: "Reposition your finger"
        case .tooDark: "Make sure the flash isn't blocked"
        case .lifted: "Finger lifted — measurement paused"
        }
    }

    internal var subtitle: String {
        switch self {
        case .partial: "Part of the camera is still uncovered"
        case .pressure: "Pressing hard squeezes out the pulse"
        case .saturated: "Too much light is getting through"
        case .tooDark: "The image is too dark to read"
        case .lifted: "Place your finger back to resume"
        }
    }

    internal var symbol: String {
        switch self {
        case .partial: "circle.lefthalf.filled"
        case .pressure: "chevron.down.2"
        case .saturated: "sun.max.fill"
        case .tooDark: "bolt.slash.fill"
        case .lifted: "pause.fill"
        }
    }

    internal var color: Color {
        switch self {
        case .partial, .pressure: .qualityFair
        case .saturated, .tooDark: .warning
        case .lifted: .qualityPoor
        }
    }
}

private struct FingerPromptBanner: View {
    internal let prompt: FingerPrompt

    internal var body: some View {
        HStack(spacing: 16) {
            Image(systemName: prompt.symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(prompt.color)
                .frame(width: 48, height: 48)
                .background(prompt.color.opacity(0.18), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(prompt.title).font(.headline).foregroundStyle(Color.textPrimary)
                Text(prompt.subtitle).font(.subheadline).foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.surface, in: .rect(cornerRadius: Metrics.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Metrics.cardRadius).strokeBorder(prompt.color.opacity(0.45)))
        .accessibilityElement(children: .combine)
    }
}

private struct LiveMeasurementView: View {
    internal let phase: MeasurementFeature.Phase
    internal let snapshot: PulseSnapshot
    internal let remainingSeconds: Int

    private var isCalibrating: Bool { phase == .calibrating }
    private var prompt: FingerPrompt? { FingerPrompt(snapshot.fingerState, isPaused: phase == .paused) }

    internal var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let prompt {
                    FingerPromptBanner(prompt: prompt)
                }
                ring
                    .frame(width: 280, height: 280)
                    .padding(.top, prompt == nil ? 24 : 0)
                if isCalibrating {
                    calibratingCaption
                }
                qualityChip
                livePulseCard
                if !isCalibrating {
                    VStack(spacing: 6) {
                        Text("Keep your finger still").font(.headline).foregroundStyle(Color.textPrimary)
                        Text("Breathe normally and stay relaxed").font(.subheadline).foregroundStyle(Color.textSecondary)
                    }
                } else {
                    Text("Keep your finger still").font(.subheadline).foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.vertical, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var ring: some View {
        ZStack {
            if isCalibrating {
                IndeterminateRing()
            } else {
                ProgressRing(progress: Double(MeasurementFeature.duration - remainingSeconds) / Double(MeasurementFeature.duration))
            }
            VStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(LinearGradient.accent)
                    .opacity(isCalibrating ? 0.7 : 1)
                if let bpm = snapshot.bpm, !isCalibrating {
                    Text("\(bpm)")
                        .font(.heroNumeral)
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                } else {
                    Text("– –")
                        .font(.heroNumeral)
                        .foregroundStyle(Color.textTertiary)
                }
                Text("BPM").font(.title3.weight(.semibold)).foregroundStyle(Color.textSecondary)
                if !isCalibrating {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Self.countdown(remainingSeconds))
                            .font(.title2.weight(.bold).monospacedDigit())
                            .foregroundStyle(Color.textPrimary)
                        Text("left").font(.subheadline).foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var calibratingCaption: some View {
        VStack(spacing: 8) {
            Text("Hold still…")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text("Calibrating to your signal")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
            ShimmerBar()
                .frame(height: 6)
                .padding(.horizontal, 40)
                .padding(.top, 12)
        }
    }

    private var qualityChip: some View {
        Group {
            if let quality = snapshot.quality, !isCalibrating {
                QualityBadge(quality, prefix: "Signal:")
            } else {
                HStack(spacing: 6) {
                    Circle().fill(Color.textSecondary).frame(width: 8, height: 8)
                    Text("Quality: Reading…")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.surfaceElevated, in: .capsule)
    }

    private var livePulseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Live pulse").microLabelStyle()
                Spacer()
                if phase == .measuring {
                    HStack(spacing: 6) {
                        Text("Live").microLabelStyle(.accentStart)
                        Circle().fill(Color.accentStart).frame(width: 8, height: 8)
                    }
                }
            }
            WaveformView(points: snapshot.waveform, lineWidth: isCalibrating ? 1.5 : 3)
                .opacity(isCalibrating ? 0.5 : 1)
                .frame(height: 90)
        }
        .card()
    }

    private static func countdown(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct IndeterminateRing: View {
    @State private var isRotating = false

    internal var body: some View {
        ZStack {
            Circle().stroke(Color.surfaceElevated, lineWidth: 16)
            Circle()
                .trim(from: 0, to: 0.22)
                .stroke(
                    AngularGradient(colors: [.clear, .accentEnd], center: .center, startAngle: .zero, endAngle: .degrees(80)),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(isRotating ? 270 : -90))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                isRotating = true
            }
        }
    }
}

private struct ShimmerBar: View {
    @State private var offset: CGFloat = -1

    internal var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.surfaceElevated)
                .overlay {
                    LinearGradient(colors: [.clear, .accentEnd, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: proxy.size.width * 0.4)
                        .offset(x: offset * proxy.size.width * 0.7)
                }
                .clipShape(.capsule)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                offset = 1
            }
        }
    }
}

private struct ResultView: View {
    internal let reading: PulseReading
    @Binding internal var saveToHealth: Bool
    internal let onSave: () -> Void
    internal let onDiscard: () -> Void

    internal var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Metrics.cardSpacing) {
                    ReadingSummaryView(reading: reading)
                    healthRow
                    Text("Not a medical device. Don't use for diagnosis.")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, Metrics.screenMargin)
                .padding(.vertical, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 12) {
                Button("Save", action: onSave)
                    .buttonStyle(.primary)
                Button(action: onDiscard) {
                    Text("Discard").foregroundStyle(Color.accentEnd)
                }
                .buttonStyle(.secondary)
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, 8)
        }
    }

    private var healthRow: some View {
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
            Toggle("Save to Apple Health", isOn: $saveToHealth)
                .labelsHidden()
                .tint(.qualityGood)
        }
        .card(padding: 18)
    }
}

private struct FailedView: View {
    internal let reason: MeasurementFeature.FailureReason
    internal let onTryAgain: () -> Void
    internal let onClose: () -> Void

    internal var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color.qualityFair)
                        .frame(width: 96, height: 96)
                        .background(Color.qualityFair.opacity(0.3), in: .circle)
                        .padding(18)
                        .background(Color.qualityFair.opacity(0.12), in: .circle)
                        .padding(.top, 40)
                    Text("Couldn't get a reliable reading")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(explanation)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                    if !tips.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                if index > 0 {
                                    Divider().overlay(Color.separator).padding(.leading, 64)
                                }
                                TipRow(tip: tip)
                            }
                        }
                        .background(Color.surface, in: .rect(cornerRadius: Metrics.cardRadius))
                    }
                }
                .padding(.horizontal, Metrics.screenMargin)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 12) {
                Button("Try Again", action: onTryAgain)
                    .buttonStyle(.primary)
                Button(action: onClose) {
                    Text("Close").foregroundStyle(Color.accentEnd)
                }
                .buttonStyle(.secondary)
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, 8)
        }
    }

    private var explanation: String {
        switch reason {
        case .unreliable: "Nothing was saved. This usually happens when:"
        case .fingerLifted: "Nothing was saved. Your finger was off the camera for more than 10 seconds."
        case .cameraUnavailable: "Nothing was saved. The camera or flash couldn't be started. Close other camera apps and try again."
        case .overheated: "Nothing was saved. Your iPhone is too warm. Let it cool down and try again."
        case .interrupted: "Nothing was saved. The measurement stopped when the app left the screen."
        }
    }

    private var tips: [Tip] {
        switch reason {
        case .unreliable: [.moved, .lifted]
        case .fingerLifted: [.lifted]
        case .cameraUnavailable, .overheated, .interrupted: []
        }
    }
}

private enum Tip {
    case moved
    case lifted
}

private struct TipRow: View {
    internal let tip: Tip

    internal var body: some View {
        HStack(spacing: 16) {
            Image(systemName: tip == .moved ? "arrow.left.and.right" : "arrow.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.qualityFair)
                .frame(width: 48, height: 48)
                .background(Color.qualityFair.opacity(0.18), in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(tip == .moved ? "You moved too much" : "Your finger lifted off the camera")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Text(tip == .moved ? "Rest your hand on a table" : "Keep light, steady contact")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Measuring") {
    MeasurementView(
        store: Store(initialState: MeasurementFeature.State(captureRate: 60)) {
            MeasurementFeature()
        }
    )
}
