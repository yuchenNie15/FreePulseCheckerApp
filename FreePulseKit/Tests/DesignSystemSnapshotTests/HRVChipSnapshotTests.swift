import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct HRVChipSnapshotTests {
    @Test internal func snapshots() {
        HRVChip_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
