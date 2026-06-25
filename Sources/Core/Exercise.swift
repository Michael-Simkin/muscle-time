/// One of the exercises the muscle-break wheel can land on.
///
/// The case order is also the visual order of the wheel's wedges, so the
/// overlay can pick a random index and trust it maps to the matching wedge.
public enum Exercise: String, CaseIterable, Sendable {
    case pushUps
    case pullUps
    case plank
    case treadmill

    public var displayName: String {
        switch self {
        case .pushUps: "Push-ups"
        case .pullUps: "Pull-ups"
        case .plank: "Plank"
        case .treadmill: "Treadmill"
        }
    }
}
