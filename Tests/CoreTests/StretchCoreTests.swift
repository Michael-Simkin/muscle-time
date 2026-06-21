@testable import StretchCore
import Testing

@Test
func `stretch schedule stores durations`() {
    let schedule = StretchSchedule(interval: .seconds(2700), stretchDuration: .seconds(60))

    #expect(schedule.interval == .seconds(2700))
    #expect(schedule.stretchDuration == .seconds(60))
}
