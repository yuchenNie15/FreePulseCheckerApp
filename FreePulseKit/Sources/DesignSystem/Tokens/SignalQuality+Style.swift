import PulseEngine
import SwiftUI

extension SignalQuality {
    public var color: Color {
        switch self {
        case .good: .qualityGood
        case .fair: .qualityFair
        case .poor: .qualityPoor
        }
    }

    public var title: String {
        switch self {
        case .good: "High accuracy"
        case .fair: "Medium accuracy"
        case .poor: "Low accuracy"
        }
    }
}
