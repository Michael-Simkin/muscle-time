public struct MuscleTimeSchedule: Sendable, Equatable {
    public static let defaultInterval: Duration = .seconds(2700)
    public static let minimumInterval: Duration = .seconds(600)
    public static let maximumInterval: Duration = .seconds(43200)
    public static let defaultBreakDuration: Duration = .seconds(10)

    public var interval: Duration
    public var breakDuration: Duration

    public init(
        interval: Duration = Self.defaultInterval,
        breakDuration: Duration = Self.defaultBreakDuration,
    ) {
        self.interval = interval
        self.breakDuration = breakDuration
    }

    public static func interval(fromHHMM text: String) -> Duration? {
        guard text.count == 5 else {
            return nil
        }

        let colonIndex = text.index(text.startIndex, offsetBy: 2)
        guard text[colonIndex] == ":" else {
            return nil
        }

        let hoursText = String(text.prefix(2))
        let minutesText = String(text.suffix(2))

        guard let hours = Int(hoursText), let minutes = Int(minutesText), (0 ... 59).contains(minutes) else {
            return nil
        }

        let totalSeconds = (hours * 3600) + (minutes * 60)
        let interval = Duration.seconds(totalSeconds)

        guard isValidInterval(interval) else {
            return nil
        }

        return interval
    }

    public static func hhmmString(for interval: Duration) -> String {
        let totalMinutes = seconds(in: interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        return "\(twoDigitString(hours)):\(twoDigitString(minutes))"
    }

    public static func isValidInterval(_ interval: Duration) -> Bool {
        interval >= minimumInterval && interval <= maximumInterval
    }

    public static func seconds(in duration: Duration) -> Int {
        Int(duration.components.seconds)
    }

    private static func twoDigitString(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
