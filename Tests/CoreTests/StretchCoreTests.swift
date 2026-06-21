import Foundation
@testable import StretchCore
import Testing

@Test
func `stretch schedule stores durations`() {
    let schedule = StretchSchedule(interval: .seconds(2700), stretchDuration: .seconds(60))

    #expect(schedule.interval == .seconds(2700))
    #expect(schedule.stretchDuration == .seconds(60))
}

@Test
func `schedule parses strict hhmm intervals`() {
    #expect(StretchSchedule.interval(fromHHMM: "00:10") == .seconds(600))
    #expect(StretchSchedule.interval(fromHHMM: "12:00") == .seconds(43200))
    #expect(StretchSchedule.interval(fromHHMM: "0:10") == nil)
    #expect(StretchSchedule.interval(fromHHMM: "00:09") == nil)
    #expect(StretchSchedule.interval(fromHHMM: "12:01") == nil)
}

@Test
func `schedule formats hhmm intervals`() {
    #expect(StretchSchedule.hhmmString(for: .seconds(600)) == "00:10")
    #expect(StretchSchedule.hhmmString(for: .seconds(2700)) == "00:45")
    #expect(StretchSchedule.hhmmString(for: .seconds(43200)) == "12:00")
}

@Test
func `session starts break when waiting time expires`() {
    let startDate = Date(timeIntervalSinceReferenceDate: 1000)
    let dueDate = startDate.addingTimeInterval(600)
    var session = StretchSession(schedule: StretchSchedule(interval: .seconds(600), stretchDuration: .seconds(10)))

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
    var session = StretchSession(schedule: StretchSchedule(interval: .seconds(600), stretchDuration: .seconds(10)))

    session.start(at: startDate)
    _ = session.advance(at: dueDate)

    #expect(session.advance(at: completionDate) == .breakCompleted)
    #expect(session.nextBreakAt == completionDate.addingTimeInterval(600))
}

@Test
func `session postpone waits for the postpone duration`() {
    let date = Date(timeIntervalSinceReferenceDate: 1000)
    var session = StretchSession(schedule: StretchSchedule(interval: .seconds(600), stretchDuration: .seconds(10)))

    session.postpone(at: date, by: .seconds(300))

    #expect(session.nextBreakAt == date.addingTimeInterval(300))
}
