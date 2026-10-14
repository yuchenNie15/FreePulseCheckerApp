import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct CalibratingCaptionSnapshotTests {
    @Test internal func snapshots() {
        CalibratingCaption_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
