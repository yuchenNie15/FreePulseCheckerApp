import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct StartButtonSnapshotTests {
    @Test internal func snapshots() {
        StartButton_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
