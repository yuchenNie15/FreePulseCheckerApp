import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct ViewModifiersSnapshotTests {
    @Test internal func snapshots() {
        ViewModifiers_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
