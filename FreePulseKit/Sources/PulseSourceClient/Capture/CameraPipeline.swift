import AppClients
import AVFoundation
import ComposableArchitecture
import CoreMotion
import PulseEngine

/** Streams rear camera frames, with the torch on, and accelerometer samples into one continuation.
- Mutable state is confined to `queue`, which also runs the video and motion callbacks.
- `stop()` is idempotent and runs on every exit path, turning the torch off. */
internal final class CameraPipeline: NSObject, @unchecked Sendable {
    internal static let torchLevel = min(0.6, AVCaptureDevice.maxAvailableTorchLevel)
    internal static let motionInterval: TimeInterval = 1.0 / 50

    @Dependency(\.log) internal var log

    internal let queue = DispatchQueue(label: "FreePulseCheck.CameraPipeline")
    internal let session = AVCaptureSession()
    internal var device: AVCaptureDevice?
    private let continuation: AsyncThrowingStream<PulseSourceEvent, any Error>.Continuation
    private let motion = CMMotionManager()
    private let motionQueue = OperationQueue()
    private var observers: [any NSObjectProtocol] = []
    /// Presentation time of the first frame, in host-clock seconds; motion timestamps share that clock.
    private var origin: TimeInterval?
    private var exposureLock = ExposureLock()
    private var isStopped = false

    internal init(continuation: AsyncThrowingStream<PulseSourceEvent, any Error>.Continuation) {
        self.continuation = continuation
        super.init()
        motionQueue.underlyingQueue = queue
        motionQueue.maxConcurrentOperationCount = 1
    }

    internal static func stream() -> AsyncThrowingStream<PulseSourceEvent, any Error> {
        AsyncThrowingStream { continuation in
            let pipeline = CameraPipeline(continuation: continuation)
            continuation.onTermination = { _ in pipeline.stop() }
            pipeline.start()
        }
    }

    internal func start() {
        queue.async { [self] in
            do {
                guard !isOverheated else { throw PulseSourceError.overheated }
                try configureSession()
                observeInterruptions()
                session.startRunning()
                try turnTorchOn()
                startMotion()
            } catch {
                fail(error)
            }
        }
    }

    internal func stop() {
        queue.async { [self] in
            guard !isStopped else { return }
            isStopped = true
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
            motion.stopAccelerometerUpdates()
            turnTorchOff()
            session.stopRunning()
            log.write(LogEntry(.info, .measurement, "Camera stopped"))
        }
    }

    private func fail(_ error: any Error) {
        log.write(LogEntry(.error, .measurement, "Camera failed: \(error)"))
        continuation.finish(throwing: error)
    }

    private var isOverheated: Bool {
        ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    }

    private func startMotion() {
        guard motion.isAccelerometerAvailable else { return }
        motion.accelerometerUpdateInterval = Self.motionInterval
        motion.startAccelerometerUpdates(to: motionQueue) { [self] data, _ in
            guard let data, let origin else { return }
            let a = data.acceleration
            let magnitude = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
            continuation.yield(.motion(MotionSample(timestamp: data.timestamp - origin, magnitude: magnitude)))
        }
    }

    private func observeInterruptions() {
        let center = NotificationCenter.default
        let failures: [(Notification.Name, AnyObject?, PulseSourceError)] = [
            (AVCaptureSession.wasInterruptedNotification, session, .interrupted),
            (AVCaptureSession.runtimeErrorNotification, session, .cameraUnavailable),
            (ProcessInfo.thermalStateDidChangeNotification, nil, .overheated),
        ]
        observers = failures.map { name, object, failure in
            center.addObserver(forName: name, object: object, queue: nil) { [self] _ in
                queue.async { [self] in
                    guard !isStopped, failure != .overheated || isOverheated else { return }
                    fail(failure)
                }
            }
        }
    }
}

extension CameraPipeline: AVCaptureVideoDataOutputSampleBufferDelegate {
    internal func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !isStopped, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        let origin = origin ?? presentationTime
        self.origin = origin

        let frame = PPGFrame(timestamp: presentationTime - origin, cells: FrameSampler.cells(from: pixelBuffer))
        continuation.yield(.frame(frame))

        let fingerOnLens = FingerDetector.classify(frame) == .present
        if let action = ExposureLock.update(fingerOnLens: fingerOnLens, at: frame.timestamp, &exposureLock) {
            setExposureLocked(action == .lock)
        }
    }
}
