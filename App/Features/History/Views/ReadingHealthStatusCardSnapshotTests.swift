import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct ReadingHealthStatusCardSnapshotTests {
    @Test internal func snapshots() {
        ReadingHealthStatusCard_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
