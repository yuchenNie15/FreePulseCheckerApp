import Foundation

public struct TimedValue: Equatable, Sendable {
    public var time: TimeInterval
    public var value: Double

    public init(time: TimeInterval, value: Double) {
        self.time = time
        self.value = value
    }
}

/// Colour statistics for one cell of the 8×8 grid sampled from the centre of a frame, on a 0–255 scale.
public struct CellStats: Equatable, Sendable {
    public var meanRed: Double
    public var meanGreen: Double
    public var meanBlue: Double
    /// Fraction of the cell's pixels whose red channel is 255.
    public var saturatedFraction: Double

    public init(meanRed: Double, meanGreen: Double, meanBlue: Double, saturatedFraction: Double = 0) {
        self.meanRed = meanRed
        self.meanGreen = meanGreen
        self.meanBlue = meanBlue
        self.saturatedFraction = saturatedFraction
    }
}

public struct PPGFrame: Equatable, Sendable {
    /// Seconds since the first frame of the capture session, from the camera's presentation timestamps.
    public var timestamp: TimeInterval
    public var cells: [CellStats]

    public init(timestamp: TimeInterval, cells: [CellStats]) {
        self.timestamp = timestamp
        self.cells = cells
    }

    public var red: Double { Stats.mean(cells.map(\.meanRed)) }
    public var green: Double { Stats.mean(cells.map(\.meanGreen)) }
    public var saturatedFraction: Double { Stats.mean(cells.map(\.saturatedFraction)) }
}

public struct MotionSample: Equatable, Sendable {
    public var timestamp: TimeInterval
    /// Accelerometer magnitude in g; 1.0 when the phone is at rest.
    public var magnitude: Double

    public init(timestamp: TimeInterval, magnitude: Double) {
        self.timestamp = timestamp
        self.magnitude = magnitude
    }
}

public enum FingerState: Equatable, Sendable {
    case absent
    case partial
    case saturated
    case tooDark
    case tooMuchPressure
    case present

    public var isOnLens: Bool { self == .present || self == .tooMuchPressure }
}

public enum SignalQuality: String, Codable, Equatable, Sendable {
    case good
    case fair
    case poor

    public init(score: Double) {
        switch score {
        case 0.7...: self = .good
        case 0.4..<0.7: self = .fair
        default: self = .poor
        }
    }
}
