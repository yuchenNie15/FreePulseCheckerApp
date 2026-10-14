import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct MeasureStartCardSnapshotTests {
    @Test internal func snapshots() {
        MeasureStartCard_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
