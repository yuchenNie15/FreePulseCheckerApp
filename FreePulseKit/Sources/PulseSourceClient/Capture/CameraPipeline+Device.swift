import AppClients
import AVFoundation

extension CameraPipeline {
    internal func configureSession() throws {
        guard let device = CaptureFormat.rearCamera(), device.hasTorch,
              let choice = CaptureFormat.best(for: device),
              let input = try? AVCaptureDeviceInput(device: device)
        else { throw PulseSourceError.cameraUnavailable }

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        guard session.canAddInput(input), session.canAddOutput(output) else {
            throw PulseSourceError.configurationFailed
        }
        session.addInput(input)
        session.addOutput(output)
        if let connection = output.connection(with: .video), connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .off
        }

        do {
            try device.lockForConfiguration()
        } catch {
            throw PulseSourceError.configurationFailed
        }
        defer { device.unlockForConfiguration() }
        device.activeFormat = choice.format
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(choice.frameRate))
        device.activeVideoMinFrameDuration = frameDuration
        device.activeVideoMaxFrameDuration = frameDuration
        if choice.format.isVideoHDRSupported {
            device.automaticallyAdjustsVideoHDREnabled = false
            device.isVideoHDREnabled = false
        }
        if device.isLowLightBoostSupported {
            device.automaticallyEnablesLowLightBoostWhenAvailable = false
        }
        self.device = device

        let dimensions = choice.dimensions
        log.write(LogEntry(.info, .measurement, "Camera format \(dimensions.width)x\(dimensions.height) at \(choice.frameRate) fps"))
    }

    /// Throws `.overheated` when the system has disabled the torch, which it does under thermal pressure.
    internal func turnTorchOn() throws {
        guard let device else { throw PulseSourceError.cameraUnavailable }
        guard device.isTorchAvailable else { throw PulseSourceError.overheated }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            try device.setTorchModeOn(level: Self.torchLevel)
        } catch {
            throw PulseSourceError.configurationFailed
        }
        log.write(LogEntry(.info, .measurement, "Torch on at \(Self.torchLevel)"))
    }

    internal func turnTorchOff() {
        guard let device, device.hasTorch, (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }
        device.torchMode = .off
    }

    internal func setExposureLocked(_ locked: Bool) {
        guard let device, (try? device.lockForConfiguration()) != nil else { return }
        defer { device.unlockForConfiguration() }

        let exposure: AVCaptureDevice.ExposureMode = locked ? .locked : .continuousAutoExposure
        if device.isExposureModeSupported(exposure) {
            device.exposureMode = exposure
        }
        let whiteBalance: AVCaptureDevice.WhiteBalanceMode = locked ? .locked : .continuousAutoWhiteBalance
        if device.isWhiteBalanceModeSupported(whiteBalance) {
            device.whiteBalanceMode = whiteBalance
        }
        let focus: AVCaptureDevice.FocusMode = locked ? .locked : .continuousAutoFocus
        if device.isFocusModeSupported(focus) {
            device.focusMode = focus
        }
        log.write(LogEntry(.info, .measurement, locked ? "Exposure locked" : "Exposure back to auto"))
    }
}
