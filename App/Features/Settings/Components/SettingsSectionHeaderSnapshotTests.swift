import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct SettingsSectionHeaderSnapshotTests {
    @Test internal func snapshots() {
        SettingsSectionHeader_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
