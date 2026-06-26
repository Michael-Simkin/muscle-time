import Foundation

public enum MuscleTimeSessionState: Sendable, Equatable {
    case idle
    case waitingUntil(Date)
    case active(until: Date)
    case skipped(until: Date)
}

public enum MuscleTimeSessionTransition: Sendable, Equatable {
    case none
    case breakStarted
    case breakCompleted
}

public struct MuscleTimeSession: Sendable, Equatable {
    public private(set) var schedule: MuscleTimeSchedule
    public private(set) var state: MuscleTimeSessionState

    public init(schedule: MuscleTimeSchedule = MuscleTimeSchedule()) {
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

    public mutating func updateSchedule(_ schedule: MuscleTimeSchedule, at date: Date) {
        self.schedule = schedule
        reset(at: date)
    }

    /// Moves the pending deadline later by `interval` seconds. Used to exclude
    /// time the Mac spent asleep so the countdown resumes where it left off
    /// instead of elapsing during sleep. No-op while idle (no deadline to move).
    public mutating func shiftDeadline(by interval: TimeInterval) {
        switch state {
        case .idle:
            break
        case let .waitingUntil(date):
            state = .waitingUntil(date.addingTimeInterval(interval))
        case let .active(until):
            state = .active(until: until.addingTimeInterval(interval))
        case let .skipped(date):
            state = .skipped(until: date.addingTimeInterval(interval))
        }
    }

    public mutating func postpone(at date: Date, by duration: Duration) {
        state = .skipped(until: adding(duration, to: date))
    }

    public mutating func completeBreak(at date: Date) {
        reset(at: date)
    }

    public mutating func advance(at date: Date) -> MuscleTimeSessionTransition {
        switch state {
        case .idle:
            start(at: date)
            return .none
        case let .waitingUntil(nextBreakDate), let .skipped(nextBreakDate):
            guard date >= nextBreakDate else {
                return .none
            }

            state = .active(until: adding(schedule.breakDuration, to: date))
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
        date.addingTimeInterval(TimeInterval(MuscleTimeSchedule.seconds(in: duration)))
    }
}
