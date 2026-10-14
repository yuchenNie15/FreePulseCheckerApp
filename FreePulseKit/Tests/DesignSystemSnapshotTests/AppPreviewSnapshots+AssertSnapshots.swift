import DesignSystem
import SnapshotTestSupport

extension AppPreviewSnapshots {
    /** Asserts every configuration against its reference image, named after the configuration.
    - Parameter layout: Full-screen device or size-to-fit rendering.
    - Parameter record: Re-records the reference images instead of comparing.
    - Parameter fileID: The caller's file ID, for failure reporting.
    - Parameter file: The caller's file path; reference images mirror it under `Snapshots/` at the repo root.
    - Parameter testName: Prefix for the reference image names.
    - Parameter line: The caller's line, for failure reporting.
    - Parameter column: The caller's column, for failure reporting. */
    internal func assertSnapshots(
        layout: SnapshotLayout = .device,
        record: Bool = updateSnapshots,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        SnapshotTestSupport.assertSnapshots(
            of: configurations.map { ($0.name, configure($0.state)) },
            layout: layout, record: record,
            fileID: fileID, file: file, testName: testName, line: line, column: column
        )
    }
}
