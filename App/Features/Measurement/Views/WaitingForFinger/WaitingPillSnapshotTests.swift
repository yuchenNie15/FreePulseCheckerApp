import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct WaitingPillSnapshotTests {
    @Test internal func snapshots() {
        WaitingPill_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
