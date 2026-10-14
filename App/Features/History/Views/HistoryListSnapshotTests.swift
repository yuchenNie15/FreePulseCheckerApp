import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct HistoryListSnapshotTests {
    @Test internal func snapshots() {
        HistoryList_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
