import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct LivePulseCardSnapshotTests {
    @Test internal func snapshots() {
        LivePulseCard_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
