import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct LicensesViewSnapshotTests {
    @Test internal func snapshots() {
        LicensesView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
