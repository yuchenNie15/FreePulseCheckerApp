import ComposableArchitecture
import DesignSystem
import SwiftUI

internal struct SettingsView: View {
    @Bindable private var store: StoreOf<SettingsFeature>
    @Environment(\.scenePhase) private var scenePhase

    internal init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    internal var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List {
                HealthSection(access: store.healthAccess) { store.send(.healthRowTapped) }
                MeasurementSection()
                PrivacySection()
                AboutSection()
                SettingsVersionFooter(appVersion: store.appVersion)
            }
            .settingsListStyle()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        } destination: { store in
            switch store.case {
            case .disclaimer:
                DisclaimerView()
            case .licenses:
                LicensesView(licenses: License.all)
            case let .license(license):
                LicenseDetailView(license: license)
            }
        }
        .task { await store.send(.task).finish() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.sceneBecameActive) }
        }
    }
}
