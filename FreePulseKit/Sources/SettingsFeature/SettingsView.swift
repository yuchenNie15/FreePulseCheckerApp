import ComposableArchitecture
import DesignSystem
import HealthKitClient
import SwiftUI

public struct SettingsView: View {
    @Bindable private var store: StoreOf<SettingsFeature>
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List {
                healthSection
                measurementSection
                privacySection
                aboutSection
                versionFooter
            }
            .settingsListStyle()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        } destination: { store in
            switch store.case {
            case .disclaimer:
                DisclaimerView()
            case .licenses:
                LicensesView()
            case let .license(license):
                LicenseDetailView(license: license)
            }
        }
        .task { await store.send(.task).finish() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.sceneBecameActive) }
        }
    }

    private var healthSection: some View {
        Section {
            Button {
                store.send(.healthRowTapped)
            } label: {
                SettingsRow(
                    icon: "heart.fill",
                    iconColor: .accentStart,
                    tileColor: .white,
                    title: "Apple Health",
                    value: store.healthAccess?.statusText,
                    valueColor: store.healthAccess == .authorized ? .qualityGood : .textSecondary,
                    showsChevron: store.healthAccess?.isTappable == true
                )
            }
            .disabled(store.healthAccess?.isTappable != true)
            .settingsRowBackground()
        } header: {
            SectionHeader("Apple Health")
        } footer: {
            SectionFooter("Heart rate and HRV (SDNN) are written to Apple Health when you save a reading.")
        }
    }

    private var measurementSection: some View {
        Section {
            SettingsRow(icon: "timer", tileColor: .warning, title: "Duration", value: "60 s")
                .settingsRowBackground()
            SettingsRow(icon: "hand.point.up.left.fill", tileColor: .accentStart, title: "Method", value: "Fingertip on rear camera")
                .settingsRowBackground()
        } header: {
            SectionHeader("Measurement")
        } footer: {
            SectionFooter("Fixed length keeps HRV readings comparable.")
        }
    }

    private var privacySection: some View {
        Section {
            SettingsRow(icon: "lock.fill", tileColor: Color(hex: 0x0A84FF), title: "On-device only")
                .settingsRowBackground()
        } header: {
            SectionHeader("Privacy")
        } footer: {
            SectionFooter("No account and no network. Readings stay on this iPhone unless you save them to Apple Health.")
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink(state: SettingsFeature.Path.State.disclaimer) {
                SettingsRow(icon: "info", tileColor: Color(hex: 0x5E5CE6), title: "Disclaimer", value: "Not a medical device")
            }
            .settingsRowBackground()
            NavigationLink(state: SettingsFeature.Path.State.licenses) {
                SettingsRow(
                    icon: "doc.text",
                    tileColor: Color(hex: 0x636366),
                    title: "Open-source licenses",
                    subtitle: "Includes ClimbPulse (MIT)"
                )
            }
            .settingsRowBackground()
        } header: {
            SectionHeader("About")
        }
    }

    private var versionFooter: some View {
        VStack(spacing: 6) {
            if let version = store.appVersion {
                Text("Free Pulse Check \(version)")
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

private struct DisclaimerView: View {
    internal var body: some View {
        ScrollView {
            Text(
                "Free Pulse Check is a wellness tool, not a medical device. It doesn't diagnose, treat or prevent any condition. If you have concerns about your heart, talk to a doctor."
            )
            .font(.body)
            .foregroundStyle(Color.textPrimary)
            .card()
            .padding(Metrics.screenMargin)
        }
        .screenBackground()
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LicensesView: View {
    internal var body: some View {
        List {
            Section {
                ForEach(License.all) { license in
                    NavigationLink(state: SettingsFeature.Path.State.license(license)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(license.name).font(.body).foregroundStyle(Color.textPrimary)
                            Text(license.kind).font(.footnote).foregroundStyle(Color.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .settingsRowBackground()
                }
            } footer: {
                SectionFooter("The signal-processing approach was informed by ClimbPulse.")
            }
        }
        .settingsListStyle()
        .navigationTitle("Open-source licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LicenseDetailView: View {
    internal let license: License

    internal var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let note = license.note {
                    Text(note).font(.subheadline).foregroundStyle(Color.textSecondary)
                }
                Text(license.text)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Color.textPrimary)
                    .textSelection(.enabled)
            }
            .card(padding: 16)
            .padding(Metrics.screenMargin)
        }
        .screenBackground()
        .navigationTitle(license.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsRow: View {
    internal let icon: String
    internal var iconColor: Color = .white
    internal let tileColor: Color
    internal let title: String
    internal var subtitle: String?
    internal var value: String?
    internal var valueColor: Color = .textSecondary
    internal var showsChevron = false

    internal var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 30, height: 30)
                .background(tileColor, in: .rect(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(Color.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(Color.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if let value {
                Text(value).font(.body).foregroundStyle(valueColor).multilineTextAlignment(.trailing)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct SectionHeader: View {
    private let title: String

    internal init(_ title: String) {
        self.title = title
    }

    internal var body: some View {
        Text(title).microLabelStyle(.textSecondary)
    }
}

private struct SectionFooter: View {
    private let text: String

    internal init(_ text: String) {
        self.text = text
    }

    internal var body: some View {
        Text(text).font(.footnote).foregroundStyle(Color.textSecondary)
    }
}

extension View {
    fileprivate func settingsListStyle() -> some View {
        self
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .screenBackground()
            .tint(Color.accentEnd)
    }

    fileprivate func settingsRowBackground() -> some View {
        self
            .listRowBackground(Color.surface)
            .listRowSeparatorTint(Color.separator)
    }
}

extension HealthAccess {
    fileprivate var statusText: String {
        switch self {
        case .authorized: "Connected"
        case .notDetermined, .denied: "Not connected"
        case .unavailable: "Unavailable"
        }
    }

    fileprivate var isTappable: Bool {
        self != .unavailable
    }
}
