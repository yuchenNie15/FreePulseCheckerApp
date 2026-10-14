import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct LicenseDetailViewSnapshotTests {
    @Test internal func snapshots() {
        LicenseDetailView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
