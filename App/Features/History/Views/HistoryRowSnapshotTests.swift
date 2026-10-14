import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct HistoryRowSnapshotTests {
    @Test internal func snapshots() {
        HistoryRow_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
