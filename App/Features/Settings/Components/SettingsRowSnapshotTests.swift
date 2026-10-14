import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct SettingsRowSnapshotTests {
    @Test internal func snapshots() {
        SettingsRow_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
