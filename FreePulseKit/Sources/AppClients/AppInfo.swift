import ComposableArchitecture
import Foundation

@DependencyClient
public struct AppInfo: Sendable {
    /// "0.1 (1)": marketing version and build number.
    public var version: @Sendable () -> String = { "" }
}

extension AppInfo: DependencyKey {
    public static let liveValue = AppInfo(
        version: {
            let info = Bundle.main.infoDictionary ?? [:]
            let marketing = info["CFBundleShortVersionString"] as? String ?? "?"
            let build = info["CFBundleVersion"] as? String ?? "?"
            return "\(marketing) (\(build))"
        }
    )

    public static let previewValue = AppInfo(version: { "0.1 (1)" })
    public static let testValue = AppInfo()
}

extension DependencyValues {
    public var appInfo: AppInfo {
        get { self[AppInfo.self] }
        set { self[AppInfo.self] = newValue }
    }
}
