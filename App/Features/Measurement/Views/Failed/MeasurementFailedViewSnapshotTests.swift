import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasurementFailedViewSnapshotTests {
    @Test internal func snapshots() {
        MeasurementFailedView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
