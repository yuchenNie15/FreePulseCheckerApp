import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite struct AppViewSnapshotTests {
    @Test func snapshots() {
        AppView_Previews.snapshots.assertSnapshots()
    }
}
