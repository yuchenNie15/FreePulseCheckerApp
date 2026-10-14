import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct SettingsVersionFooterSnapshotTests {
    @Test internal func snapshots() {
        SettingsVersionFooter_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
