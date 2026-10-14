import ComposableArchitecture
import Foundation
import os

public enum LogCategory: String, CaseIterable, Sendable {
    case app
    case history
    case measure
    case measurement
    case readingStore
    case settings
}

public enum LogLevel: Equatable, Sendable {
    case debug
    case info
    case error
}

public struct LogEntry: Equatable, Sendable {
    public var level: LogLevel
    public var category: LogCategory
    public var message: String

    public init(_ level: LogLevel, _ category: LogCategory, _ message: String) {
        self.level = level
        self.category = category
        self.message = message
    }
}

/** Writes to the unified log under the app's bundle ID, one `os.Logger` category per `LogCategory`.
- Messages are logged `.public`, so they must never carry heart rate, HRV or other health values. */
@DependencyClient
public struct LogClient: Sendable {
    public var write: @Sendable (_ entry: LogEntry) -> Void
}

extension LogClient {
    public func debug<Action>(_ category: LogCategory, _ message: String) -> Effect<Action> {
        effect(LogEntry(.debug, category, message))
    }

    public func info<Action>(_ category: LogCategory, _ message: String) -> Effect<Action> {
        effect(LogEntry(.info, category, message))
    }

    public func error<Action>(_ category: LogCategory, _ message: String) -> Effect<Action> {
        effect(LogEntry(.error, category, message))
    }

    private func effect<Action>(_ entry: LogEntry) -> Effect<Action> {
        .run { _ in write(entry) }
    }
}

extension LogClient: DependencyKey {
    public static let liveValue: LogClient = {
        let subsystem = Bundle.main.bundleIdentifier ?? "FreePulseCheck"
        let loggers = Dictionary(
            uniqueKeysWithValues: LogCategory.allCases.map { ($0, Logger(subsystem: subsystem, category: $0.rawValue)) }
        )
        return LogClient { entry in
            guard let logger = loggers[entry.category] else { return }
            switch entry.level {
            case .debug: logger.debug("\(entry.message, privacy: .public)")
            case .info: logger.info("\(entry.message, privacy: .public)")
            case .error: logger.error("\(entry.message, privacy: .public)")
            }
        }
    }()

    public static let previewValue = LogClient { _ in }
    /// Silent, so reducer tests only assert logs when they override `write`.
    public static let testValue = LogClient { _ in }
}

extension DependencyValues {
    public var log: LogClient {
        get { self[LogClient.self] }
        set { self[LogClient.self] = newValue }
    }
}
