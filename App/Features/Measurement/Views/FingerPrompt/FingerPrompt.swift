import DesignSystem
import PulseEngine
import SwiftUI

internal enum FingerPrompt: Equatable {
    case partial
    case pressure
    case saturated
    case tooDark
    case lifted

    internal init?(_ fingerState: FingerState, isPaused: Bool) {
        switch fingerState {
        case .partial: self = .partial
        case .tooMuchPressure: self = .pressure
        case .saturated: self = .saturated
        case .tooDark: self = .tooDark
        case .absent where isPaused: self = .lifted
        case .absent, .present: return nil
        }
    }

    internal var title: String {
        switch self {
        case .partial: "Cover the whole lens"
        case .pressure: "Press a little lighter"
        case .saturated: "Reposition your finger"
        case .tooDark: "Make sure the flash isn't blocked"
        case .lifted: "Finger lifted — measurement paused"
        }
    }

    internal var subtitle: String {
        switch self {
        case .partial: "Part of the camera is still uncovered"
        case .pressure: "Pressing hard squeezes out the pulse"
        case .saturated: "Too much light is getting through"
        case .tooDark: "The image is too dark to read"
        case .lifted: "Place your finger back to resume"
        }
    }

    internal var symbol: String {
        switch self {
        case .partial: "circle.lefthalf.filled"
        case .pressure: "chevron.down.2"
        case .saturated: "sun.max.fill"
        case .tooDark: "bolt.slash.fill"
        case .lifted: "pause.fill"
        }
    }

    internal var color: Color {
        switch self {
        case .partial, .pressure: .qualityFair
        case .saturated, .tooDark: .warning
        case .lifted: .qualityPoor
        }
    }
}
