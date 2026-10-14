import PulseEngine
import Testing
@testable import PulseSourceClient

@Suite internal struct FrameSamplerTests {
    @Test internal func uniformFrameGivesEqualCellMeans() {
        let cells = sample(width: 160, height: 120) { _, _ in (red: 200, green: 70, blue: 20) }

        #expect(cells.count == 64)
        #expect(cells.allSatisfy { $0 == CellStats(meanRed: 200, meanGreen: 70, meanBlue: 20, saturatedFraction: 0) })
    }

    @Test internal func channelsAreReadFromBGRAOrder() {
        let cells = sample(width: 160, height: 120) { _, _ in (red: 10, green: 20, blue: 30) }

        #expect(cells[0].meanRed == 10)
        #expect(cells[0].meanGreen == 20)
        #expect(cells[0].meanBlue == 30)
    }

    @Test internal func pixelsOutsideTheCentreAreIgnored() {
        let cells = sample(width: 160, height: 120) { x, y in
            let inCentre = (32..<128).contains(x) && (24..<96).contains(y)
            return inCentre ? (red: 200, green: 70, blue: 20) : (red: 0, green: 255, blue: 255)
        }

        #expect(cells.allSatisfy { $0.meanRed == 200 && $0.meanGreen == 70 })
    }

    @Test internal func cellsFollowRowMajorGridOrder() {
        let cells = sample(width: 160, height: 120) { x, _ in (red: x < 80 ? 100 : 200, green: 0, blue: 0) }

        #expect(cells[0].meanRed == 100)
        #expect(cells[7].meanRed == 200)
        #expect(cells[56].meanRed == 100)
        #expect(cells[63].meanRed == 200)
    }

    @Test internal func saturatedRedIsCountedPerCell() {
        let cells = sample(width: 160, height: 120) { x, _ in (red: x.isMultiple(of: 2) ? 255 : 254, green: 0, blue: 0) }

        #expect(cells.allSatisfy { $0.saturatedFraction == 0.5 })
    }

    @Test internal func tinyFrameGivesNoCells() {
        #expect(sample(width: 8, height: 8) { _, _ in (red: 200, green: 70, blue: 20) }.isEmpty)
    }
}

@Suite internal struct ExposureLockTests {
    @Test internal func locksAfterTheFingerSettles() {
        var lock = ExposureLock()

        #expect(ExposureLock.update(fingerOnLens: true, at: 0, &lock) == nil)
        #expect(ExposureLock.update(fingerOnLens: true, at: 0.9, &lock) == nil)
        #expect(ExposureLock.update(fingerOnLens: true, at: 1.0, &lock) == .lock)
        #expect(lock.isLocked)
    }

    @Test internal func aBriefGapRestartsTheSettleTime() {
        var lock = ExposureLock()

        _ = ExposureLock.update(fingerOnLens: true, at: 0, &lock)
        _ = ExposureLock.update(fingerOnLens: false, at: 0.5, &lock)

        #expect(ExposureLock.update(fingerOnLens: true, at: 0.6, &lock) == nil)
        #expect(ExposureLock.update(fingerOnLens: true, at: 1.5, &lock) == nil)
        #expect(ExposureLock.update(fingerOnLens: true, at: 1.6, &lock) == .lock)
    }

    @Test internal func unlocksAfterTheFingerHasBeenOffAsLong() {
        var lock = ExposureLock()
        _ = ExposureLock.update(fingerOnLens: true, at: 0, &lock)
        _ = ExposureLock.update(fingerOnLens: true, at: 1, &lock)

        #expect(ExposureLock.update(fingerOnLens: false, at: 2, &lock) == nil)
        #expect(ExposureLock.update(fingerOnLens: false, at: 3, &lock) == .unlock)
        #expect(!lock.isLocked)
    }
}

/// Builds a BGRA buffer with 16 bytes of row padding, as camera buffers have, and samples it.
private func sample(
    width: Int,
    height: Int,
    pixel: (_ x: Int, _ y: Int) -> (red: UInt8, green: UInt8, blue: UInt8)
) -> [CellStats] {
    let bytesPerRow = width * 4 + 16
    var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)
    for y in 0..<height {
        for x in 0..<width {
            let colour = pixel(x, y)
            let offset = y * bytesPerRow + x * 4
            bytes[offset] = colour.blue
            bytes[offset + 1] = colour.green
            bytes[offset + 2] = colour.red
            bytes[offset + 3] = 255
        }
    }
    return bytes.withUnsafeBufferPointer { buffer in
        FrameSampler.cells(bgra: buffer.baseAddress!, width: width, height: height, bytesPerRow: bytesPerRow)
    }
}
