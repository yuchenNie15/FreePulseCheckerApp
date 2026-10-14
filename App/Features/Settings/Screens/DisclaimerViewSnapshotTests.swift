import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct DisclaimerViewSnapshotTests {
    @Test internal func snapshots() {
        DisclaimerView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
