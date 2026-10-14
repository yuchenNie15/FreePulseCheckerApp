import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct QualityBadgeSnapshotTests {
    @Test internal func snapshots() {
        QualityBadge_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
