import SnapshotTestSupport
import Testing
@testable import DesignSystem

@MainActor
@Suite internal struct WaveformViewSnapshotTests {
    @Test internal func snapshots() {
        WaveformView_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
