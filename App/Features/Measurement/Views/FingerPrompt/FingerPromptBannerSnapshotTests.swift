import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct FingerPromptBannerSnapshotTests {
    @Test internal func snapshots() {
        FingerPromptBanner_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
