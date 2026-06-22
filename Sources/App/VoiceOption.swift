import MuscleCore

struct VoiceOption: Identifiable, Equatable {
    static let fallback = VoiceOption(
        id: SettingsStore.defaultVoiceIdentifier,
        displayName: "Xavier — Dominating Metallic Announcer",
        resourceName: "VoiceXavierDominatingMetallicAnnouncer",
    )

    static let all = [
        fallback,
        VoiceOption(
            id: "guy-upbeat-radio-announcer",
            displayName: "Guy — Upbeat TV Radio Announcer",
            resourceName: "VoiceGuyUpbeatRadioAnnouncer",
        ),
    ]

    let id: String
    let displayName: String
    let resourceName: String

    static func option(for identifier: String) -> VoiceOption {
        all.first { $0.id == identifier } ?? fallback
    }
}
