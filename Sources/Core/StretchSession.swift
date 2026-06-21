import Foundation

public enum StretchSessionState: Sendable, Equatable {
    case idle
    case waitingUntil(Date)
    case active(until: Date)
    case skipped(until: Date)
}
