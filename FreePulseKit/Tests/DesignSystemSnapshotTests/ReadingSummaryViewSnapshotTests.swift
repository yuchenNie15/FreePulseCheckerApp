import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct ReadingSummaryViewSnapshotTests {
    @Test internal func snapshots() {
        ReadingSummaryView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
