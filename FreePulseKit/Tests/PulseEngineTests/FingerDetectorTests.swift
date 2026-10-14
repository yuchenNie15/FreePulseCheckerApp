import Testing
@testable import PulseEngine

@Suite struct FingerDetectorTests {
    @Test func evenlyLitRedFrameIsPresent() {
        #expect(FingerDetector.classify(frame(red: 200, green: 70)) == .present)
    }

    @Test func bareLensIsAbsent() {
        #expect(FingerDetector.classify(frame(red: 120, green: 110)) == .absent)
    }

    @Test func halfCoveredLensIsPartial() {
        let cells = (0..<64).map { index in
            index < 40
                ? CellStats(meanRed: 200, meanGreen: 70, meanBlue: 20)
                : CellStats(meanRed: 120, meanGreen: 110, meanBlue: 100)
        }
        #expect(FingerDetector.classify(PPGFrame(timestamp: 0, cells: cells)) == .partial)
    }

    @Test func darkFrameIsTooDark() {
        #expect(FingerDetector.classify(frame(red: 30, green: 10)) == .tooDark)
    }

    @Test func clippedRedIsSaturated() {
        #expect(FingerDetector.classify(frame(red: 250, green: 80, saturated: 0.5)) == .saturated)
    }

    @Test func unevenRedIsNotAFinger() {
        let cells = (0..<64).map { index in
            CellStats(meanRed: index.isMultiple(of: 2) ? 100 : 250, meanGreen: 30, meanBlue: 10)
        }
        #expect(FingerDetector.classify(PPGFrame(timestamp: 0, cells: cells)) == .absent)
    }

    @Test func entersPresentAfterTenFingerFrames() {
        var detector = FingerDetector()
        let states = (0..<10).map { FingerDetector.update(with: frame(red: 200, green: 70, at: Double($0) / 60), perfusionIndex: nil, &detector) }
        #expect(states.prefix(9).allSatisfy { $0 == .absent })
        #expect(states.last == .present)
    }

    @Test func leavesPresentAfterSixBareFrames() {
        var detector = FingerDetector()
        for index in 0..<10 {
            _ = FingerDetector.update(with: frame(red: 200, green: 70, at: Double(index) / 60), perfusionIndex: nil, &detector)
        }
        let states = (0..<6).map { _ in FingerDetector.update(with: frame(red: 120, green: 110), perfusionIndex: nil, &detector) }
        #expect(states.prefix(5).allSatisfy { $0 == .present })
        #expect(states.last == .absent)
    }

    /** A finger is on the lens but the pulse amplitude stays at 0.01% of brightness, as when pressing hard.

    Expected: `.present` for the first 2 s, then `.tooMuchPressure`. */
    @Test func weakPulseForTwoSecondsIsTooMuchPressure() {
        var detector = FingerDetector()
        var last = FingerState.absent
        var lastPresentTime = 0.0
        for index in 0..<240 {
            let time = Double(index) / 60
            last = FingerDetector.update(with: frame(red: 200, green: 70, at: time), perfusionIndex: 0.0001, &detector)
            if last == .present { lastPresentTime = time }
        }
        #expect(last == .tooMuchPressure)
        #expect(abs(lastPresentTime - (9.0 / 60 + 2)) < 0.05)
    }

    private func frame(red: Double, green: Double, saturated: Double = 0, at time: Double = 0) -> PPGFrame {
        PPGFrame(timestamp: time, cells: SyntheticPPG.uniformCells(red: red, green: green, saturated: saturated))
    }
}
