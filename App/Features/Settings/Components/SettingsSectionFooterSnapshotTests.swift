import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct SettingsSectionFooterSnapshotTests {
    @Test internal func snapshots() {
        SettingsSectionFooter_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
