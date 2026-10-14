import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct EmptyHistoryViewSnapshotTests {
    @Test internal func snapshots() {
        EmptyHistoryView_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
