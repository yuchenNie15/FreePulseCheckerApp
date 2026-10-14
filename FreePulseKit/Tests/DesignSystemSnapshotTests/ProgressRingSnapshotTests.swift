import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct ProgressRingSnapshotTests {
    @Test internal func snapshots() {
        ProgressRing_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
