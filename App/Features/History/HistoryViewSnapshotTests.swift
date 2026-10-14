import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct HistoryViewSnapshotTests {
    @Test internal func snapshots() {
        HistoryView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
