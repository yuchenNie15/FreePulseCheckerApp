import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct RecentReadingsSectionSnapshotTests {
    @Test internal func snapshots() {
        RecentReadingsSection_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
