import ComposableArchitecture
import DesignSystem
import HealthKitClient
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

internal struct SettingsView_Previews: PreviewProvider {
    internal struct PreviewState {
        internal var healthAccess: HealthAccess?
        internal var appVersion: String?
        internal var dynamicTypeSize: DynamicTypeSize = .large
    }

    internal static var previews: some View {
        snapshots.previews
    }

    internal static var snapshots: AppPreviewSnapshots<PreviewState> {
        AppPreviewSnapshots(
            configurations: [
                .init(name: "Loading", state: PreviewState()),
                .init(name: "Unavailable", state: PreviewState(healthAccess: .unavailable, appVersion: "0.1 (1)")),
                .init(name: "NotDetermined", state: PreviewState(healthAccess: .notDetermined, appVersion: "0.1 (1)")),
                .init(name: "Authorized", state: PreviewState(healthAccess: .authorized, appVersion: "0.1 (1)")),
                .init(name: "Denied", state: PreviewState(healthAccess: .denied, appVersion: "0.1 (1)")),
                .init(
                    name: "AuthorizedAccessibility3",
                    state: PreviewState(healthAccess: .authorized, appVersion: "0.1 (1)", dynamicTypeSize: .accessibility3)
                ),
            ],
            configure: { state in
                SettingsView(
                    store: Store(
                        initialState: SettingsFeature.State(appVersion: state.appVersion, healthAccess: state.healthAccess)
                    ) { EmptyReducer() }
                )
                .environment(\.dynamicTypeSize, state.dynamicTypeSize)
            }
        )
    }
}
