import AVFAudio
import Foundation

// swiftlint:disable:next unused_import
import OSLog

@MainActor
final class VoicePlayer {
    private let logger = Logger(subsystem: "com.michael.MuscleTime", category: "VoicePlayer")
    private var player: AVAudioPlayer?

    func play(voice: VoiceOption) {
        stop()

        guard let url = Bundle.main.url(forResource: voice.resourceName, withExtension: voice.fileExtension) else {
            logger.error("Missing voice resource: \(voice.resourceName, privacy: .public)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            self.player = player

            if !player.play() {
                logger.error("Voice playback did not start: \(voice.resourceName, privacy: .public)")
            }
        } catch {
            logger.error("Voice playback failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
