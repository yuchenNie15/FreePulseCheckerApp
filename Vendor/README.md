# Vendored packages

## swift-snapshot-testing 1.19.6

Upstream 1.19.6 (and `main` as of 2026-09-21) references `UIHostingController._disableSafeArea`,
which the iOS 27 SDK removed, so it no longer compiles. This copy drops that pre-iOS 16.4 branch
in `Sources/SnapshotTesting/Snapshotting/SwiftUIView.swift` and removes the package's own test
targets. The Xcode project references it as a local package, which also overrides the remote copy
that `swiftui-preview-snapshots` depends on. Delete this folder once upstream ships a fix.
