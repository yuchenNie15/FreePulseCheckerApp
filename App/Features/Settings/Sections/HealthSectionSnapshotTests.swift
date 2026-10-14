import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct HealthSectionSnapshotTests {
    @Test internal func snapshots() {
        HealthSection_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
