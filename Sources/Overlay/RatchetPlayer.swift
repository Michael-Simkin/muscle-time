import AVFAudio
import Foundation

// swiftlint:disable:next unused_import
import OSLog

/// Plays the wheel's tick ("ratchet") click. The wheel fires a tick on every
/// peg it crosses, so ticks come fast while it spins quickly and space out as it
/// slows. To keep those rapid, overlapping clicks crisp, this preloads a small
/// pool of players once and round-robins through them instead of loading the
/// file on every tick.
@MainActor
final class RatchetPlayer {
    private let logger = Logger(subsystem: "com.michael.MuscleTime", category: "RatchetPlayer")
    private var pool: [AVAudioPlayer] = []
    private var next = 0

    init(resource: String, fileExtension: String, voices: Int = 8) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
            logger.error("Missing tick resource: \(resource, privacy: .public)")
            return
        }

        for _ in 0 ..< voices {
            guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            pool.append(player)
        }
    }

    func tick() {
        guard !pool.isEmpty else { return }

        let player = pool[next]
        next = (next + 1) % pool.count
        player.currentTime = 0
        player.play()
    }
}
