import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct LiveBPMRingSnapshotTests {
    @Test internal func snapshots() {
        LiveBPMRing_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
