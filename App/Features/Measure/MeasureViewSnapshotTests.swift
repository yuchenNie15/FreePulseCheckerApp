import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasureViewSnapshotTests {
    @Test internal func snapshots() {
        MeasureView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
