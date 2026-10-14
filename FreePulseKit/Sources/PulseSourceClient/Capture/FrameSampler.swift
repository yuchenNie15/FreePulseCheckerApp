import Accelerate
import CoreVideo
import PulseEngine

/** Reduces a BGRA frame to `gridSize` × `gridSize` cell statistics over its centre `roiFraction`.
- Every `rowStep`-th row is sampled; cell means barely move and the work halves. */
internal enum FrameSampler {
    internal static let gridSize = 8
    internal static let roiFraction = 0.6
    internal static let rowStep = 2

    internal static func cells(from pixelBuffer: CVPixelBuffer) -> [CellStats] {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return [] }
        return cells(
            bgra: base.assumingMemoryBound(to: UInt8.self),
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer),
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer)
        )
    }

    internal static func cells(bgra base: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int) -> [CellStats] {
        let cellWidth = Int(Double(width) * roiFraction) / gridSize
        let cellHeight = Int(Double(height) * roiFraction) / gridSize
        guard cellWidth > 0, cellHeight > 0 else { return [] }
        let roiWidth = cellWidth * gridSize
        let originX = (width - roiWidth) / 2
        let originY = (height - cellHeight * gridSize) / 2

        let cellCount = gridSize * gridSize
        var red = [Double](repeating: 0, count: cellCount)
        var green = [Double](repeating: 0, count: cellCount)
        var blue = [Double](repeating: 0, count: cellCount)
        var saturated = [Double](repeating: 0, count: cellCount)
        var sampledRows = [Int](repeating: 0, count: gridSize)
        var row = [Float](repeating: 0, count: roiWidth)
        var signs = [Float](repeating: 0, count: roiWidth)

        for y in stride(from: 0, to: cellHeight * gridSize, by: rowStep) {
            let gridRow = y / cellHeight
            sampledRows[gridRow] += 1
            let rowStart = base + (originY + y) * bytesPerRow + originX * 4

            addCellSums(rowStart + 2, into: &red, gridRow: gridRow, cellWidth: cellWidth, row: &row)
            addSaturatedCounts(row, into: &saturated, gridRow: gridRow, cellWidth: cellWidth, signs: &signs)
            addCellSums(rowStart + 1, into: &green, gridRow: gridRow, cellWidth: cellWidth, row: &row)
            addCellSums(rowStart, into: &blue, gridRow: gridRow, cellWidth: cellWidth, row: &row)
        }

        return (0..<cellCount).map { index in
            let samples = Double(sampledRows[index / gridSize] * cellWidth)
            return CellStats(
                meanRed: red[index] / samples,
                meanGreen: green[index] / samples,
                meanBlue: blue[index] / samples,
                saturatedFraction: saturated[index] / samples
            )
        }
    }

    /// Converts one channel of a BGRA row into `row`, then adds each cell's slice of it to `sums`.
    private static func addCellSums(
        _ channelStart: UnsafePointer<UInt8>,
        into sums: inout [Double],
        gridRow: Int,
        cellWidth: Int,
        row: inout [Float]
    ) {
        vDSP_vfltu8(channelStart, 4, &row, 1, vDSP_Length(row.count))
        row.withUnsafeBufferPointer { buffer in
            for column in 0..<gridSize {
                var sum: Float = 0
                vDSP_sve(buffer.baseAddress! + column * cellWidth, 1, &sum, vDSP_Length(cellWidth))
                sums[gridRow * gridSize + column] += Double(sum)
            }
        }
    }

    /// Counts red values of 255 per cell: thresholding at 254.5 maps each pixel to ±1, so count = (sum + n) / 2.
    private static func addSaturatedCounts(
        _ redRow: [Float],
        into counts: inout [Double],
        gridRow: Int,
        cellWidth: Int,
        signs: inout [Float]
    ) {
        var threshold: Float = 254.5
        var one: Float = 1
        vDSP_vthrsc(redRow, 1, &threshold, &one, &signs, 1, vDSP_Length(redRow.count))
        signs.withUnsafeBufferPointer { buffer in
            for column in 0..<gridSize {
                var sum: Float = 0
                vDSP_sve(buffer.baseAddress! + column * cellWidth, 1, &sum, vDSP_Length(cellWidth))
                counts[gridRow * gridSize + column] += (Double(sum) + Double(cellWidth)) / 2
            }
        }
    }
}
