import AVFoundation
import ComposableArchitecture

public enum CameraAuthorization: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
}

@DependencyClient
public struct CameraPermissionClient: Sendable {
    public var status: @Sendable () -> CameraAuthorization = { .notDetermined }
    /// Shows the system prompt when undetermined; returns whether access is granted.
    public var request: @Sendable () async -> Bool = { false }
}

extension CameraPermissionClient: DependencyKey {
    public static let liveValue: CameraPermissionClient = {
        #if targetEnvironment(simulator)
        return CameraPermissionClient(status: { .authorized }, request: { true })
        #else
        return CameraPermissionClient(
            status: {
                switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized: .authorized
                case .notDetermined: .notDetermined
                default: .denied
                }
            },
            request: { await AVCaptureDevice.requestAccess(for: .video) }
        )
        #endif
    }()

    public static let previewValue = CameraPermissionClient(status: { .authorized }, request: { true })
    public static let testValue = CameraPermissionClient()
}

extension DependencyValues {
    public var cameraPermission: CameraPermissionClient {
        get { self[CameraPermissionClient.self] }
        set { self[CameraPermissionClient.self] = newValue }
    }
}
