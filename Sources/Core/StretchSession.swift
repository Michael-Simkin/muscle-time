import Foundation

public enum StretchSessionState: Sendable, Equatable {
    case idle
    case waitingUntil(Date)
    case active(until: Date)
    case skipped(until: Date)
}

public enum StretchSessionTransition: Sendable, Equatable {
    case none
    case breakStarted
    case breakCompleted
}

public struct StretchSession: Sendable, Equatable {
    public private(set) var schedule: StretchSchedule
    public private(set) var state: StretchSessionState

    public init(schedule: StretchSchedule = StretchSchedule()) {
        self.schedule = schedule
        state = .idle
    }

    public var nextBreakAt: Date? {
        switch state {
        case .idle, .active:
            nil
        case let .waitingUntil(date), let .skipped(date):
            date
        }
    }

    public mutating func start(at date: Date) {
        state = .waitingUntil(adding(schedule.interval, to: date))
    }

    public mutating func reset(at date: Date) {
        state = .waitingUntil(adding(schedule.interval, to: date))
    }

    public mutating func updateSchedule(_ schedule: StretchSchedule, at date: Date) {
        self.schedule = schedule
        reset(at: date)
    }

    public mutating func postpone(at date: Date, by duration: Duration) {
        state = .skipped(until: adding(duration, to: date))
    }

    public mutating func completeBreak(at date: Date) {
        reset(at: date)
    }

    public mutating func advance(at date: Date) -> StretchSessionTransition {
        switch state {
        case .idle:
            start(at: date)
            return .none
        case let .waitingUntil(nextBreakDate), let .skipped(nextBreakDate):
            guard date >= nextBreakDate else {
                return .none
            }

            state = .active(until: adding(schedule.stretchDuration, to: date))
            return .breakStarted
        case let .active(until):
            guard date >= until else {
                return .none
            }

            completeBreak(at: date)
            return .breakCompleted
        }
    }

    private func adding(_ duration: Duration, to date: Date) -> Date {
        date.addingTimeInterval(TimeInterval(StretchSchedule.seconds(in: duration)))
    }
}
