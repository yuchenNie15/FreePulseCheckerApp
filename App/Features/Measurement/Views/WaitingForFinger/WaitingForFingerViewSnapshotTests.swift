import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct WaitingForFingerViewSnapshotTests {
    @Test internal func snapshots() {
        WaitingForFingerView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
