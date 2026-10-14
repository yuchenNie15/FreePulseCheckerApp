import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct HistorySectionHeaderSnapshotTests {
    @Test internal func snapshots() {
        HistorySectionHeader_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
