import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasurementHeaderSnapshotTests {
    @Test internal func snapshots() {
        MeasurementHeader_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
