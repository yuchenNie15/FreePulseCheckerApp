import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasurementActionButtonsSnapshotTests {
    @Test internal func snapshots() {
        MeasurementActionButtons_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
