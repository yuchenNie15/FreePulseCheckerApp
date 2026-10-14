import Models
import PulseEngine
import SwiftUI

public struct QualityBadge: View {
    private let quality: SignalQuality
    private let prefix: String?

    public init(_ quality: SignalQuality, prefix: String? = nil) {
        self.quality = quality
        self.prefix = prefix
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle().fill(quality.color).frame(width: 8, height: 8)
            Text(prefix.map { "\($0) \(quality.title)" } ?? quality.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
    }
}

/// A capsule chip showing RMSSD, or a dash when HRV is unavailable.
public struct HRVChip: View {
    private let rmssd: Double?

    public init(rmssd: Double?) {
        self.rmssd = rmssd
    }

    public var body: some View {
        Text(rmssd.map { "RMSSD \(Int($0.rounded())) ms" } ?? "HRV —")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.accentEnd)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accentTint, in: .capsule)
    }
}

/// Draws -1...1 points left to right as a smooth pulse line.
public struct WaveformShape: Shape {
    private let points: [Double]

    public init(points: [Double]) {
        self.points = points
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let step = rect.width / CGFloat(points.count - 1)
        for (index, value) in points.enumerated() {
            let point = CGPoint(x: CGFloat(index) * step, y: rect.midY - CGFloat(value) * rect.height / 2)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        return path
    }
}

public struct WaveformView: View {
    private let points: [Double]
    private let lineWidth: CGFloat

    public init(points: [Double], lineWidth: CGFloat = 3) {
        self.points = points
        self.lineWidth = lineWidth
    }

    public var body: some View {
        WaveformShape(points: points)
            .stroke(LinearGradient.accentHorizontal, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .shadow(color: .accentStart.opacity(0.6), radius: 6)
    }
}

/// A gradient ring filled clockwise from the top; `progress` is 0...1.
public struct ProgressRing: View {
    private let progress: Double
    private let lineWidth: CGFloat

    public init(progress: Double, lineWidth: CGFloat = 16) {
        self.progress = progress
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle().stroke(Color.surfaceElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(LinearGradient.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: .accentStart.opacity(0.6), radius: 10)
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

/// The glowing circular hero button on the Measure tab.
public struct StartButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle().stroke(Color.accentStart.opacity(0.35), lineWidth: 2).frame(width: 196, height: 196)
                Circle().stroke(Color.accentStart.opacity(0.7), lineWidth: 6).frame(width: 176, height: 176)
                Circle()
                    .fill(LinearGradient.accent)
                    .frame(width: 148, height: 148)
                    .shadow(color: .accentStart.opacity(0.7), radius: 24)
                VStack(spacing: 8) {
                    Image(systemName: "heart.fill").font(.system(size: 52))
                    Text("START").font(.system(size: 15, weight: .bold)).tracking(2)
                }
                .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start Measurement")
    }
}

/// A saved reading as a tappable card: BPM, RMSSD chip, quality and date.
public struct ReadingCard: View {
    private let reading: PulseReading
    private let now: Date

    public init(reading: PulseReading, now: Date = Date()) {
        self.reading = reading
        self.now = now
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(reading.bpm)").font(.cardNumeral).foregroundStyle(Color.textPrimary)
                    Text("BPM").font(.headline).foregroundStyle(Color.textSecondary)
                }
                HRVChip(rmssd: reading.rmssd)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 14) {
                QualityBadge(reading.quality)
                Text(ReadingDateFormatter.string(for: reading.date, now: now))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textTertiary)
                .padding(.leading, 8)
        }
        .card(padding: 18)
        .accessibilityElement(children: .combine)
    }
}

public enum ReadingDateFormatter {
    /// "Today 9:41", "Yesterday 18:02", or "Oct 12" for older dates.
    public static func string(for date: Date, now: Date, calendar: Calendar = .current) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDate(date, inSameDayAs: now) { return "Today \(time)" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday \(time)"
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
