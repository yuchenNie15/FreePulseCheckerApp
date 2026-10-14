import PulseEngine
import SwiftUI

extension Color {
    public static let background = Color(hex: 0x0B0B10)
    public static let surface = Color(hex: 0x16161E)
    public static let surfaceElevated = Color(hex: 0x1F1F2A)
    public static let separator = Color(hex: 0x2A2A35)
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0x8E8E9A)
    public static let textTertiary = Color(hex: 0x5A5A66)
    public static let accentStart = Color(hex: 0xFF2D55)
    public static let accentEnd = Color(hex: 0xFF6B9A)
    public static let accentTint = Color(hex: 0x2A1520)
    public static let qualityGood = Color(hex: 0x30D158)
    public static let qualityFair = Color(hex: 0xFFD60A)
    public static let qualityPoor = Color(hex: 0xFF453A)
    public static let warning = Color(hex: 0xFF9F0A)
    public static let destructive = Color(hex: 0xFF3B30)

    public init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension LinearGradient {
    /// Diagonal, for filled shapes.
    public static let accent = LinearGradient(
        colors: [.accentStart, .accentEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// Horizontal, for strokes and buttons.
    public static let accentHorizontal = LinearGradient(
        colors: [.accentStart, .accentEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
}

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
        case .good: "Good"
        case .fair: "Fair"
        case .poor: "Poor"
        }
    }
}

extension Font {
    public static let heroNumeral = Font.system(size: 92, weight: .heavy, design: .rounded)
    public static let cardNumeral = Font.system(size: 34, weight: .bold, design: .rounded)
    public static let rowNumeral = Font.system(size: 26, weight: .bold, design: .rounded)
    public static let microLabel = Font.system(size: 11, weight: .bold)
}

public enum Metrics {
    public static let screenMargin: CGFloat = 16
    public static let cardPadding: CGFloat = 20
    public static let cardSpacing: CGFloat = 12
    public static let cardRadius: CGFloat = 20
    public static let buttonRadius: CGFloat = 18
}
