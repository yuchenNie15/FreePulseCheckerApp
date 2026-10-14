// swift-tools-version: 6.0
import PackageDescription

private let tca = Target.Dependency.product(name: "ComposableArchitecture", package: "swift-composable-architecture")

let package = Package(
    name: "FreePulseKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "PulseEngine", targets: ["PulseEngine"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.26.2"),
    ],
    targets: [
        .target(name: "PulseEngine", dependencies: [tca]),
        .target(name: "Models", dependencies: ["PulseEngine", tca]),
        .target(name: "DesignSystem", dependencies: ["Models", "PulseEngine"]),
        .target(name: "PulseSourceClient", dependencies: ["PulseEngine", tca]),
        .target(name: "HealthKitClient", dependencies: ["Models", tca]),
        .target(name: "AppClients", dependencies: ["HealthKitClient", "Models", tca]),
        .target(
            name: "MeasurementFeature",
            dependencies: ["AppClients", "DesignSystem", "Models", "PulseEngine", "PulseSourceClient", tca]
        ),
        .target(
            name: "MeasureFeature",
            dependencies: ["AppClients", "DesignSystem", "MeasurementFeature", "Models", "PulseSourceClient", tca]
        ),
        .target(name: "HistoryFeature", dependencies: ["AppClients", "DesignSystem", "Models", tca]),
        .target(name: "SettingsFeature", dependencies: ["AppClients", "DesignSystem", "HealthKitClient", tca]),
        .target(name: "AppFeature", dependencies: ["AppClients", "DesignSystem", "HistoryFeature", "MeasureFeature", "SettingsFeature", tca]),

        .testTarget(name: "PulseEngineTests", dependencies: ["PulseEngine", tca]),
        .testTarget(name: "PulseSourceClientTests", dependencies: ["PulseSourceClient", "PulseEngine"]),
        .testTarget(name: "MeasurementFeatureTests", dependencies: ["MeasurementFeature", tca]),
        .testTarget(name: "MeasureFeatureTests", dependencies: ["MeasureFeature", tca]),
        .testTarget(name: "HistoryFeatureTests", dependencies: ["HistoryFeature", tca]),
        .testTarget(name: "SettingsFeatureTests", dependencies: ["SettingsFeature", tca]),
        .testTarget(name: "AppFeatureTests", dependencies: ["AppClients", "AppFeature", tca]),
    ]
)
