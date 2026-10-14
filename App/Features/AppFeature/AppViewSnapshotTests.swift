import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct AppViewSnapshotTests {
    @Test internal func snapshots() {
        AppView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
