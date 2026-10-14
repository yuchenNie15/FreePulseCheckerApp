import ComposableArchitecture
import Foundation
import Models

public enum AppTab: Hashable, Sendable {
    case measure
    case history
    case settings
}

extension SharedKey where Self == InMemoryKey<AppTab>.Default {
    public static var selectedTab: Self {
        Self[.inMemory("selectedTab"), default: .measure]
    }
}

extension SharedKey where Self == InMemoryKey<PulseReading.ID?>.Default {
    /// The reading pushed onto the History stack, if any.
    public static var selectedReadingID: Self {
        Self[.inMemory("selectedReadingID"), default: nil]
    }
}

extension SharedKey where Self == InMemoryKey<String?>.Default {
    /// Shown on the Measure tab after a reading saved locally but Apple Health rejected it.
    public static var healthWarning: Self {
        Self[.inMemory("healthWarning"), default: nil]
    }
}
