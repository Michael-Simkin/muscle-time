import Foundation

public struct SettingsStore: @unchecked Sendable {
    public static let defaultVoiceIdentifier = "xavier-dominating-metallic-announcer"

    private static let cycleLengthSecondsKey = "cycleLengthSeconds"
    private static let selectedVoiceIdentifierKey = "selectedVoiceIdentifier"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public init() {
        // swiftlint:disable:next no_direct_userdefaults
        self.init(defaults: UserDefaults.standard)
    }

    public var cycleLength: Duration {
        get {
            let savedSeconds = defaults.integer(forKey: Self.cycleLengthSecondsKey)
            let savedInterval = Duration.seconds(savedSeconds)

            guard StretchSchedule.isValidInterval(savedInterval) else {
                return StretchSchedule.defaultInterval
            }

            return savedInterval
        }
        nonmutating set {
            defaults.set(StretchSchedule.seconds(in: newValue), forKey: Self.cycleLengthSecondsKey)
        }
    }

    public var selectedVoiceIdentifier: String {
        get {
            guard let savedIdentifier = defaults.string(forKey: Self.selectedVoiceIdentifierKey),
                  !savedIdentifier.isEmpty
            else {
                return Self.defaultVoiceIdentifier
            }

            return savedIdentifier
        }
        nonmutating set {
            defaults.set(newValue, forKey: Self.selectedVoiceIdentifierKey)
        }
    }
}
