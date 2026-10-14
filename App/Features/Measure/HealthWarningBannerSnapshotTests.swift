import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct HealthWarningBannerSnapshotTests {
    @Test internal func snapshots() {
        HealthWarningBanner_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
