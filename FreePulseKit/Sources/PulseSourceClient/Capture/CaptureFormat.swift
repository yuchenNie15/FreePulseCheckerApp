import AVFoundation

/// The rear camera format and frame rate a measurement captures with.
internal struct CaptureFormat {
    internal let format: AVCaptureDevice.Format
    internal let frameRate: Double

    internal static let preferredFrameRates: [Double] = [60, 30]

    internal static func rearCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    /// The lowest-resolution format that runs at 60 fps, else at 30 fps.
    internal static func best(for device: AVCaptureDevice) -> CaptureFormat? {
        for rate in preferredFrameRates {
            let candidates = device.formats.filter { format in
                format.videoSupportedFrameRateRanges.contains { $0.minFrameRate <= rate && rate <= $0.maxFrameRate }
            }
            if let format = candidates.min(by: { pixelCount($0) < pixelCount($1) }) {
                return CaptureFormat(format: format, frameRate: rate)
            }
        }
        return nil
    }

    internal var dimensions: CMVideoDimensions {
        CMVideoFormatDescriptionGetDimensions(format.formatDescription)
    }

    private static func pixelCount(_ format: AVCaptureDevice.Format) -> Int {
        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        return Int(dimensions.width) * Int(dimensions.height)
    }
}
