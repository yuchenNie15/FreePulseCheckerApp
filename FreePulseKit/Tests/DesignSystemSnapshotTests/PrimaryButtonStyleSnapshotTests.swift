import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct PrimaryButtonStyleSnapshotTests {
    @Test internal func snapshots() {
        PrimaryButtonStyle_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
