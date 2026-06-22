import MuscleCore

struct VoiceOption: Identifiable, Equatable {
    static let fallback = VoiceOption(
        id: SettingsStore.defaultVoiceIdentifier,
        displayName: "Xavier — Dominating Metallic Announcer",
        resourceName: "VoiceXavierDominatingMetallicAnnouncer",
        fileExtension: "mp3",
    )

    static let all = [
        fallback,
        VoiceOption(
            id: "guy-upbeat-radio-announcer",
            displayName: "Guy — Upbeat TV Radio Announcer",
            resourceName: "VoiceGuyUpbeatRadioAnnouncer",
            fileExtension: "mp3",
        ),
        VoiceOption(
            id: "aviv",
            displayName: "Aviv",
            resourceName: "VoiceAvivMuscleTime",
            fileExtension: "m4a",
        ),
    ]

    let id: String
    let displayName: String
    let resourceName: String
    let fileExtension: String

    static func option(for identifier: String) -> VoiceOption {
        all.first { $0.id == identifier } ?? fallback
    }
}
