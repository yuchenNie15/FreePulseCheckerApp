// swift-tools-version: 6.0
import PackageDescription

private let tca = Target.Dependency.product(name: "ComposableArchitecture", package: "swift-composable-architecture")

let package = Package(
    name: "FreePulseKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AppClients", targets: ["AppClients"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "HealthKitClient", targets: ["HealthKitClient"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "PulseEngine", targets: ["PulseEngine"]),
        .library(name: "PulseSourceClient", targets: ["PulseSourceClient"]),
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

        .testTarget(name: "PulseEngineTests", dependencies: ["PulseEngine", tca]),
    ]
)
