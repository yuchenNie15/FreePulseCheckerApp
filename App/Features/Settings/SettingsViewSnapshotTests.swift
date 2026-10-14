import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct SettingsViewSnapshotTests {
    @Test internal func snapshots() {
        SettingsView_Previews.snapshots.assertSnapshots(layout: .device)
    }
}
