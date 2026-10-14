import SnapshotTestSupport
import Testing
@testable import FreePulseCheck

@MainActor
@Suite internal struct FingerOnCameraIllustrationSnapshotTests {
    @Test internal func snapshots() {
        FingerOnCameraIllustration_Previews.snapshots.assertSnapshots(layout: .component)
    }
}
