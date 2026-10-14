import SnapshotTesting
import SwiftUI
import UIKit

/// Set to true locally to re-record every reference image, then set it back.
public let updateSnapshots = false

public enum SnapshotLayout: Sendable {
    /// Full screen on an iPhone 13 Pro (390 × 844 pt), for screens.
    case device
    /// Sized to fit the view, for components and subviews.
    case component
}

/** Asserts each named view against its reference image in dark mode.
- Depends only on SnapshotTesting so a hosted test bundle never links a package the app also links.
- Parameter views: One reference image per entry, named after it.
- Parameter layout: Full-screen device or size-to-fit rendering.
- Parameter record: Re-records the reference images instead of comparing.
- Parameter fileID: The caller's file ID, for failure reporting.
- Parameter file: The caller's file path; reference images live in `__Snapshots__` beside it.
- Parameter testName: Prefix for the reference image names.
- Parameter line: The caller's line, for failure reporting.
- Parameter column: The caller's column, for failure reporting. */
@MainActor
public func assertSnapshots(
    of views: [(name: String, view: AnyView)],
    layout: SnapshotLayout,
    record: Bool,
    fileID: StaticString,
    file: StaticString,
    testName: String,
    line: UInt,
    column: UInt
) {
    let traits = UITraitCollection(userInterfaceStyle: .dark)
    let recordMode: SnapshotTestingConfiguration.Record? = record ? .all : nil
    for (name, view) in views {
        switch layout {
        case .device:
            assertSnapshot(
                of: UIHostingController(rootView: view),
                as: .image(on: .iPhone13Pro, precision: 0.98, perceptualPrecision: 0.98, traits: traits),
                named: name, record: recordMode,
                fileID: fileID, file: file, testName: testName, line: line, column: column
            )
        case .component:
            assertSnapshot(
                of: view,
                as: .image(precision: 0.98, perceptualPrecision: 0.98, layout: .sizeThatFits, traits: traits),
                named: name, record: recordMode,
                fileID: fileID, file: file, testName: testName, line: line, column: column
            )
        }
    }
}
