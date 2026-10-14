import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct EmptyReadingsCardSnapshotTests {
    @Test internal func snapshots() {
        EmptyReadingsCard_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
