// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "swiftui-preview-snapshots",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "PreviewSnapshots",
            targets: ["PreviewSnapshots"]
        ),
    ],
    targets: [
        .target(
            name: "PreviewSnapshots",
            dependencies: []
        ),
    ]
)
