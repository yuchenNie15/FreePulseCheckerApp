import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct SaveToHealthRowSnapshotTests {
    @Test internal func snapshots() {
        SaveToHealthRow_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
