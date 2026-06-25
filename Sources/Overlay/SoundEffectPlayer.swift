import AVFAudio
import Foundation

// swiftlint:disable:next unused_import
import OSLog

/// Plays short bundled sound effects (the wheel result chime, the per-exercise
/// voice announcement, and the completion flourish). Holds the players that are
/// still playing so overlapping effects are not cut off, and prunes finished
/// ones on each new play so the list stays small.
@MainActor
final class SoundEffectPlayer {
    private let logger = Logger(subsystem: "com.michael.MuscleTime", category: "SoundEffectPlayer")
    private var players: [AVAudioPlayer] = []

    func play(resource: String, fileExtension: String) {
        players.removeAll { !$0.isPlaying }

        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
            logger.error("Missing sound resource: \(resource, privacy: .public)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players.append(player)

            if !player.play() {
                logger.error("Sound playback did not start: \(resource, privacy: .public)")
            }
        } catch {
            logger.error("Sound playback failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
