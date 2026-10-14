import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasurementViewSnapshotTests {
    @Test internal func snapshots() {
        MeasurementView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
