import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct SignalQualityChipSnapshotTests {
    @Test internal func snapshots() {
        SignalQualityChip_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
