import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct CameraDeniedViewSnapshotTests {
    @Test internal func snapshots() {
        CameraDeniedView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
