import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct ReadingCardSnapshotTests {
    @Test internal func snapshots() {
        ReadingCard_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
