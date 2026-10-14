import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasurementSectionSnapshotTests {
    @Test internal func snapshots() {
        MeasurementSection_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
