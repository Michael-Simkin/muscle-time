public struct StretchSchedule: Sendable, Equatable {
    public var interval: Duration
    public var stretchDuration: Duration

    public init(interval: Duration, stretchDuration: Duration) {
        self.interval = interval
        self.stretchDuration = stretchDuration
    }
}
