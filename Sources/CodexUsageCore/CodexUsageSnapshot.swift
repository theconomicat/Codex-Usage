import Foundation

public struct CodexUsageSnapshot: Equatable, Sendable {
    public let timestamp: Date
    public let primary: UsageWindow
    public let secondary: UsageWindow
    public let planType: String?
    public let limitID: String?

    public init(
        timestamp: Date,
        primary: UsageWindow,
        secondary: UsageWindow,
        planType: String?,
        limitID: String?
    ) {
        self.timestamp = timestamp
        self.primary = primary
        self.secondary = secondary
        self.planType = planType
        self.limitID = limitID
    }

    public func normalized(at now: Date = Date()) -> CodexUsageSnapshot {
        CodexUsageSnapshot(
            timestamp: timestamp,
            primary: primary.normalized(at: now),
            secondary: secondary.normalized(at: now),
            planType: planType,
            limitID: limitID
        )
    }
}

public struct UsageWindow: Equatable, Sendable {
    public let usedPercent: Double
    public let windowMinutes: Int
    public let resetsAt: Date?

    public init(usedPercent: Double, windowMinutes: Int, resetsAt: Date?) {
        self.usedPercent = usedPercent
        self.windowMinutes = windowMinutes
        self.resetsAt = resetsAt
    }

    public var remainingPercent: Double {
        max(0, min(100, 100 - usedPercent))
    }

    public func normalized(at now: Date = Date()) -> UsageWindow {
        guard
            let resetsAt,
            windowMinutes > 0,
            resetsAt <= now
        else {
            return self
        }

        let windowSeconds = TimeInterval(windowMinutes * 60)
        let elapsedWindows = floor(now.timeIntervalSince(resetsAt) / windowSeconds) + 1
        return UsageWindow(
            usedPercent: 0,
            windowMinutes: windowMinutes,
            resetsAt: resetsAt.addingTimeInterval(elapsedWindows * windowSeconds)
        )
    }
}

public enum CodexUsageError: Error, LocalizedError {
    case codexDirectoryMissing(URL)
    case noUsageEventsFound(URL)

    public var errorDescription: String? {
        switch self {
        case .codexDirectoryMissing(let url):
            "Codex directory not found at \(url.path)"
        case .noUsageEventsFound(let url):
            "No Codex usage events found under \(url.path)"
        }
    }
}
