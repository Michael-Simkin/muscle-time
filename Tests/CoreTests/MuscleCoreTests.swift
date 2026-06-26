import Foundation
@testable import MuscleCore
import Testing

@Test
func `wheel offers exactly the four expected exercises`() {
    #expect(Exercise.allCases == [.pushUps, .pullUps, .plank, .treadmill])
}

@Test
func `every exercise has a non-empty display name`() {
    for exercise in Exercise.allCases {
        #expect(!exercise.displayName.isEmpty)
    }
}

@Test
func `muscle time schedule stores durations`() {
    let schedule = MuscleTimeSchedule(interval: .seconds(2700), breakDuration: .seconds(60))

    #expect(schedule.interval == .seconds(2700))
    #expect(schedule.breakDuration == .seconds(60))
}

@Test
func `schedule parses strict hhmm intervals`() {
    #expect(MuscleTimeSchedule.interval(fromHHMM: "00:10") == .seconds(600))
    #expect(MuscleTimeSchedule.interval(fromHHMM: "12:00") == .seconds(43200))
    #expect(MuscleTimeSchedule.interval(fromHHMM: "0:10") == nil)
    #expect(MuscleTimeSchedule.interval(fromHHMM: "00:09") == nil)
    #expect(MuscleTimeSchedule.interval(fromHHMM: "12:01") == nil)
}

@Test
func `schedule formats hhmm intervals`() {
    #expect(MuscleTimeSchedule.hhmmString(for: .seconds(600)) == "00:10")
    #expect(MuscleTimeSchedule.hhmmString(for: .seconds(2700)) == "00:45")
    #expect(MuscleTimeSchedule.hhmmString(for: .seconds(43200)) == "12:00")
}

@Test
func `session starts break when waiting time expires`() {
    let startDate = Date(timeIntervalSinceReferenceDate: 1000)
    let dueDate = startDate.addingTimeInterval(600)
    var session = MuscleTimeSession(schedule: MuscleTimeSchedule(interval: .seconds(600), breakDuration: .seconds(10)))

    session.start(at: startDate)

    #expect(session.nextBreakAt == dueDate)
    #expect(session.advance(at: dueDate) == .breakStarted)
    #expect(session.state == .active(until: dueDate.addingTimeInterval(10)))
}

@Test
func `session completion resets to the next cycle`() {
    let startDate = Date(timeIntervalSinceReferenceDate: 1000)
    let dueDate = startDate.addingTimeInterval(600)
    let completionDate = dueDate.addingTimeInterval(10)
    var session = MuscleTimeSession(schedule: MuscleTimeSchedule(interval: .seconds(600), breakDuration: .seconds(10)))

    session.start(at: startDate)
    _ = session.advance(at: dueDate)

    #expect(session.advance(at: completionDate) == .breakCompleted)
    #expect(session.nextBreakAt == completionDate.addingTimeInterval(600))
}

@Test
func `session postpone waits for the postpone duration`() {
    let date = Date(timeIntervalSinceReferenceDate: 1000)
    var session = MuscleTimeSession(schedule: MuscleTimeSchedule(interval: .seconds(600), breakDuration: .seconds(10)))

    session.postpone(at: date, by: .seconds(300))

    #expect(session.nextBreakAt == date.addingTimeInterval(300))
}

@Test
func `sleeping shifts the deadline so the countdown resumes where it left off`() {
    let startDate = Date(timeIntervalSinceReferenceDate: 1000)
    var session = MuscleTimeSession(schedule: MuscleTimeSchedule(interval: .seconds(600), breakDuration: .seconds(10)))

    session.start(at: startDate)
    // 100s in, 500s remain; the Mac then sleeps for 10_000s.
    let sleepStart = startDate.addingTimeInterval(100)
    let wake = sleepStart.addingTimeInterval(10000)
    session.shiftDeadline(by: wake.timeIntervalSince(sleepStart))

    // The break must not have fired during sleep, and 500s should still remain.
    #expect(session.advance(at: wake) == .none)
    #expect(session.nextBreakAt == wake.addingTimeInterval(500))
}
