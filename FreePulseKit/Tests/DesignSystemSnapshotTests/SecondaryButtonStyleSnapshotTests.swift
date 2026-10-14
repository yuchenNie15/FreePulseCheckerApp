import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct SecondaryButtonStyleSnapshotTests {
    @Test internal func snapshots() {
        SecondaryButtonStyle_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
