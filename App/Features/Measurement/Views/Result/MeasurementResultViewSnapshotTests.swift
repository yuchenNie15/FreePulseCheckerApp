import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasurementResultViewSnapshotTests {
    @Test internal func snapshots() {
        MeasurementResultView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
