import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct ReadingDetailViewSnapshotTests {
    @Test internal func snapshots() {
        ReadingDetailView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
