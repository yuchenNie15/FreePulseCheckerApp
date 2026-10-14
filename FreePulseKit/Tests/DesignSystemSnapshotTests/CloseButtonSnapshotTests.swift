import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct CloseButtonSnapshotTests {
    @Test internal func snapshots() {
        CloseButton_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
