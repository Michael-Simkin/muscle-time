import AppKit
import Combine
import Foundation
import MuscleCore

// swiftlint:disable:next unused_import
import OSLog

@MainActor
final class MuscleTimeTimerModel: NSObject, ObservableObject {
    @Published private var now: Date
    @Published private var session: MuscleTimeSession
    @Published private(set) var selectedVoiceIdentifier: String

    let voiceOptions = VoiceOption.all

    private let logger = Logger(subsystem: "com.michael.MuscleTime", category: "TimerModel")
    private let notificationScheduler: NotificationScheduler
    private let overlayController: OverlayController
    private let settingsStore: SettingsStore
    private let voicePlayer: VoicePlayer
    private let effectPlayer = SoundEffectPlayer()
    private var timer: Timer?
    private var sleepStartedAt: Date?

    var menuBarRemainingText: String {
        switch session.state {
        case .active:
            "Now"
        case .idle:
            "--:--"
        case let .skipped(until), let .waitingUntil(until):
            Self.remainingText(from: until.timeIntervalSince(now))
        }
    }

    var savedCycleLengthText: String {
        MuscleTimeSchedule.hhmmString(for: session.schedule.interval)
    }

    /// Fraction (0...1) of the way toward the next Muscle Time; 1 means it is active now.
    var breakProgress: Double {
        switch session.state {
        case .active:
            return 1
        case .idle:
            return 0
        case let .skipped(until), let .waitingUntil(until):
            let total = Double(MuscleTimeSchedule.seconds(in: session.schedule.interval))
            guard total > 0 else {
                return 0
            }
            let remaining = max(0, until.timeIntervalSince(now))
            return min(1, max(0, 1 - (remaining / total)))
        }
    }

    var statusText: String {
        switch session.state {
        case .active:
            "Muscle Time is active"
        case .idle:
            "Timer is starting"
        case let .skipped(until), let .waitingUntil(until):
            "Next Muscle Time in \(Self.remainingText(from: until.timeIntervalSince(now)))"
        }
    }

    override init() {
        let settingsStore = SettingsStore()
        let selectedVoiceIdentifier = VoiceOption.option(for: settingsStore.selectedVoiceIdentifier).id
        let startDate = Date()
        let schedule = MuscleTimeSchedule(interval: settingsStore.cycleLength)
        var session = MuscleTimeSession(schedule: schedule)
        session.start(at: startDate)

        now = startDate
        self.session = session
        self.selectedVoiceIdentifier = selectedVoiceIdentifier
        notificationScheduler = NotificationScheduler()
        overlayController = OverlayController()
        self.settingsStore = settingsStore
        voicePlayer = VoicePlayer()

        super.init()

        let initialMenuBarText = Self.remainingText(from: session.nextBreakAt?.timeIntervalSince(now) ?? 0)

        logger.info(
            """
            Timer model initialized. intervalSeconds=\(
                MuscleTimeSchedule.seconds(in: schedule.interval),
                privacy: .public,
            ) \
            selectedVoice=\(selectedVoiceIdentifier, privacy: .public) \
            nextBreakAt=\(session.nextBreakAt?.description ?? "missing", privacy: .public) \
            menuBarText=\(initialMenuBarText, privacy: .public)
            """,
        )

        self.settingsStore.selectedVoiceIdentifier = selectedVoiceIdentifier
        notificationScheduler.requestAuthorization()
        schedulePreBreakNotification()
        startTimer()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(noteWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil,
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(resumeAfterWake),
            name: NSWorkspace.didWakeNotification,
            object: nil,
        )
    }

    func validationMessage(for cycleLengthText: String) -> String? {
        if MuscleTimeSchedule.interval(fromHHMM: cycleLengthText) == nil {
            "Use HH:MM from 00:10 to 12:00"
        } else {
            nil
        }
    }

    func canApply(cycleLengthText: String, selectedVoiceIdentifier: String) -> Bool {
        MuscleTimeSchedule.interval(fromHHMM: cycleLengthText) != nil
            && VoiceOption.option(for: selectedVoiceIdentifier).id == selectedVoiceIdentifier
    }

    func applySettings(cycleLengthText: String, selectedVoiceIdentifier: String) {
        guard let interval = MuscleTimeSchedule.interval(fromHHMM: cycleLengthText) else {
            return
        }

        let voiceIdentifier = VoiceOption.option(for: selectedVoiceIdentifier).id
        let date = Date()
        let schedule = MuscleTimeSchedule(interval: interval)
        var updatedSession = session

        settingsStore.cycleLength = interval
        settingsStore.selectedVoiceIdentifier = voiceIdentifier
        self.selectedVoiceIdentifier = voiceIdentifier
        now = date
        updatedSession.updateSchedule(schedule, at: date)
        session = updatedSession
        voicePlayer.stop()
        overlayController.hide()
        schedulePreBreakNotification()
    }

    func applyVoiceSelection(_ selectedVoiceIdentifier: String) {
        let voiceIdentifier = VoiceOption.option(for: selectedVoiceIdentifier).id

        guard voiceIdentifier != self.selectedVoiceIdentifier else {
            return
        }

        self.selectedVoiceIdentifier = voiceIdentifier
        settingsStore.selectedVoiceIdentifier = voiceIdentifier
        voicePlayer.play(voice: VoiceOption.option(for: voiceIdentifier))
    }

    func showOverlayForTesting() {
        logger.info("Showing overlay for testing")

        overlayController.show(
            onDone: { [weak self] in
                self?.voicePlayer.stop()
                self?.overlayController.hide()
            },
            onPostpone: { [weak self] in
                self?.voicePlayer.stop()
                self?.overlayController.hide()
            },
        )

        voicePlayer.play(voice: VoiceOption.option(for: selectedVoiceIdentifier))
    }

    func completeBreak() {
        guard case .active = session.state else {
            return
        }

        let date = Date()
        var updatedSession = session

        now = date
        updatedSession.completeBreak(at: date)
        session = updatedSession
        voicePlayer.stop()
        effectPlayer.play(resource: "SoundBreakComplete", fileExtension: "mp3")
        overlayController.hide()
        schedulePreBreakNotification()
    }

    func postponeBreak() {
        guard case .active = session.state else {
            return
        }

        let date = Date()
        var updatedSession = session

        now = date
        updatedSession.postpone(at: date, by: .seconds(300))
        session = updatedSession
        voicePlayer.stop()
        overlayController.hide()
        notificationScheduler.cancelPreBreakNotification()
    }

    private func startTimer() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        logger.info("Timer started with 1 second interval.")
    }

    private func tick() {
        let date = Date()
        var updatedSession = session
        let transition = updatedSession.advance(at: date)

        now = date
        session = updatedSession

        switch transition {
        case .none:
            break
        case .breakStarted:
            logger.info("Break started from timer transition.")
            startBreak()
        case .breakCompleted:
            logger.info("Break auto-completed from timer transition.")
            voicePlayer.stop()
            overlayController.hide()
            schedulePreBreakNotification()
        }
    }

    private func startBreak() {
        logger.info("Showing Muscle Time overlay and playing selected voice.")
        notificationScheduler.cancelPreBreakNotification()
        overlayController.show(
            onDone: { [weak self] in
                self?.completeBreak()
            },
            onPostpone: { [weak self] in
                self?.postponeBreak()
            },
        )
        voicePlayer.play(voice: VoiceOption.option(for: selectedVoiceIdentifier))
    }

    private func schedulePreBreakNotification() {
        guard let nextBreakAt = session.nextBreakAt else {
            logger.info("No next break date; canceling pre-break notification.")
            notificationScheduler.cancelPreBreakNotification()
            return
        }

        logger.info("Scheduling pre-break notification. nextBreakAt=\(nextBreakAt.description, privacy: .public)")
        notificationScheduler.schedulePreBreakNotification(before: nextBreakAt)
    }

    @objc private func noteWillSleep() {
        sleepStartedAt = Date()
        logger.info("System will sleep; pausing the countdown.")
    }

    /// On wake, exclude the time spent asleep by shifting the pending deadline
    /// forward, so the countdown continues from where it was before sleep
    /// rather than resetting or firing immediately.
    @objc private func resumeAfterWake() {
        let date = Date()

        guard let sleepStartedAt else {
            logger.info("Woke without a recorded sleep start; leaving the countdown unchanged.")
            return
        }

        self.sleepStartedAt = nil
        let sleepDuration = date.timeIntervalSince(sleepStartedAt)

        guard sleepDuration > 0 else {
            return
        }

        var updatedSession = session
        updatedSession.shiftDeadline(by: sleepDuration)
        now = date
        session = updatedSession
        schedulePreBreakNotification()

        logger.info(
            "Woke after \(sleepDuration, privacy: .public)s asleep; countdown resumed where it left off.",
        )
    }

    private static func remainingText(from timeInterval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(ceil(timeInterval)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours):\(twoDigitString(minutes)):\(twoDigitString(seconds))"
        }

        return "\(minutes):\(twoDigitString(seconds))"
    }

    private static func twoDigitString(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
