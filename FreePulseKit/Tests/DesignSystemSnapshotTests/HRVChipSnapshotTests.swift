import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite struct HRVChipSnapshotTests {
    @Test func snapshots() {
        HRVChip_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
