import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct FailureTipRowSnapshotTests {
    @Test internal func snapshots() {
        FailureTipRow_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
