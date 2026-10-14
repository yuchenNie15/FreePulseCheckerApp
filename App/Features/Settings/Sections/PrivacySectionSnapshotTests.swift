import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct PrivacySectionSnapshotTests {
    @Test internal func snapshots() {
        PrivacySection_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
