import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct LiveMeasurementViewSnapshotTests {
    @Test internal func snapshots() {
        LiveMeasurementView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
