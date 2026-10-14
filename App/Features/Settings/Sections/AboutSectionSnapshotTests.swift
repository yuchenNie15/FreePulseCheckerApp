import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct AboutSectionSnapshotTests {
    @Test internal func snapshots() {
        AboutSection_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
