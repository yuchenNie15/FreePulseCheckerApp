import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct ShimmerBarSnapshotTests {
    @Test internal func snapshots() {
        ShimmerBar_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
