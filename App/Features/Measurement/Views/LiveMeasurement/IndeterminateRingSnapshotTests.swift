import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct IndeterminateRingSnapshotTests {
    @Test internal func snapshots() {
        IndeterminateRing_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
