import AppClients
import ComposableArchitecture
import DesignSystem
import Models
import PulseSourceClient
import SwiftUI

@Reducer
internal struct MeasureFeature: Sendable {
    internal static let recentCount = 3

    @ObservableState
    internal struct State: Equatable, Sendable {
        @Shared(.readings) internal var readings
        @Shared(.healthWarning) internal var healthWarning
        @Presents internal var measurement: MeasurementFeature.State?
        internal var isCameraDeniedPresented = false

        internal var recentReadings: [PulseReading] {
            Array(readings.prefix(MeasureFeature.recentCount))
        }

        internal init() {}
    }

    internal enum Action: Equatable, Sendable {
        case cameraDeniedDismissed
        case cameraPermissionResponse(granted: Bool)
        case healthWarningDismissed
        case measurement(PresentationAction<MeasurementFeature.Action>)
        case openSettingsTapped
        case readingTapped(PulseReading.ID)
        case seeAllTapped
        case startTapped
    }

    @Dependency(\.appNavigator) private var appNavigator
    @Dependency(\.cameraPermission) private var cameraPermission
    @Dependency(\.openURL) private var openURL
    @Dependency(\.pulseSource) private var pulseSource

    internal init() {}

    internal var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cameraDeniedDismissed:
                state.isCameraDeniedPresented = false
                return .none

            case let .cameraPermissionResponse(granted):
                present(&state, granted: granted)
                return .none

            case .healthWarningDismissed:
                state.$healthWarning.withLock { $0 = nil }
                return .none

            case .measurement:
                return .none

            case .openSettingsTapped:
                state.isCameraDeniedPresented = false
                return .run { _ in
                    let url = await MainActor.run { URL(string: UIApplication.openSettingsURLString) }
                    if let url {
                        await openURL(url)
                    }
                }

            case let .readingTapped(id):
                return .run { _ in appNavigator.showReading(id) }

            case .seeAllTapped:
                return .run { _ in appNavigator.showHistory() }

            case .startTapped:
                switch cameraPermission.status() {
                case .authorized:
                    present(&state, granted: true)
                    return .none
                case .denied:
                    present(&state, granted: false)
                    return .none
                case .notDetermined:
                    return .run { send in
                        await send(.cameraPermissionResponse(granted: cameraPermission.request()))
                    }
                }
            }
        }
        .ifLet(\.$measurement, action: \.measurement) { MeasurementFeature() }
    }

    private func present(_ state: inout State, granted: Bool) {
        if granted {
            state.measurement = MeasurementFeature.State(captureRate: pulseSource.captureRate())
        } else {
            state.isCameraDeniedPresented = true
        }
    }
}

internal struct MeasureView: View {
    @Bindable private var store: StoreOf<MeasureFeature>

    internal init(store: StoreOf<MeasureFeature>) {
        self.store = store
    }

    internal var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.cardSpacing) {
                Text("Free Pulse Check")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                if let warning = store.healthWarning {
                    HealthWarningBanner(message: warning) {
                        store.send(.healthWarningDismissed)
                    }
                }
                StartCard { store.send(.startTapped) }
                recentHeader
                    .padding(.top, 20)
                if store.recentReadings.isEmpty {
                    EmptyReadingsCard()
                } else {
                    ForEach(store.recentReadings) { reading in
                        Button {
                            store.send(.readingTapped(reading.id))
                        } label: {
                            ReadingCard(reading: reading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, 24)
        }
        .screenBackground()
        .fullScreenCover(item: $store.scope(\.measurement, action: \.measurement)) { measurementStore in
            MeasurementView(store: measurementStore)
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { store.isCameraDeniedPresented },
                set: { if !$0 { store.send(.cameraDeniedDismissed) } }
            )
        ) {
            CameraDeniedView {
                store.send(.openSettingsTapped)
            } onDismiss: {
                store.send(.cameraDeniedDismissed)
            }
        }
    }

    private var recentHeader: some View {
        HStack {
            Text("Recent").microLabelStyle(.textSecondary)
            Spacer()
            if !store.recentReadings.isEmpty {
                Button("See all") { store.send(.seeAllTapped) }
                    .font(.headline)
                    .foregroundStyle(Color.accentEnd)
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct StartCard: View {
    internal let onStart: () -> Void

    internal var body: some View {
        VStack(spacing: 18) {
            StartButton(action: onStart)
                .padding(.top, 8)
            VStack(spacing: 6) {
                Text("Start Measurement")
                    .font(.title2.bold())
                    .foregroundStyle(Color.textPrimary)
                Text("60 seconds · finger on rear camera")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .card(padding: 24)
    }
}

private struct EmptyReadingsCard: View {
    internal var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Image(systemName: "heart")
                    .font(.system(size: 46, weight: .regular))
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 18, weight: .semibold))
                    .offset(y: -2)
            }
            .foregroundStyle(Color.accentEnd)
            .frame(width: 96, height: 96)
            .background(Color.accentTint, in: .circle)
            Text("No measurements yet")
                .font(.title3.bold())
                .foregroundStyle(Color.textPrimary)
            Text("Your readings will appear here. Tap Start Measurement and rest your fingertip on the rear camera.")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .card()
    }
}

private struct HealthWarningBanner: View {
    internal let message: String
    internal let onDismiss: () -> Void

    internal var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.warning)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.textSecondary)
            }
            .accessibilityLabel("Dismiss")
        }
        .padding(16)
        .background(Color.surface, in: .rect(cornerRadius: Metrics.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Metrics.cardRadius).strokeBorder(Color.warning.opacity(0.45)))
    }
}

private struct CameraDeniedView: View {
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

#Preview {
    MeasureView(
        store: Store(initialState: MeasureFeature.State()) {
            MeasureFeature()
        }
    )
    .preferredColorScheme(.dark)
}
