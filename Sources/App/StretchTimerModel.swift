import AppKit
import Combine
import Foundation
import StretchCore

@MainActor
final class StretchTimerModel: NSObject, ObservableObject {
    @Published private var now: Date
    @Published private var session: StretchSession
    @Published private(set) var selectedVoiceIdentifier: String

    let voiceOptions = VoiceOption.all

    private let notificationScheduler: NotificationScheduler
    private let overlayController: OverlayController
    private let settingsStore: SettingsStore
    private let voicePlayer: VoicePlayer
    private var timer: Timer?

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
        StretchSchedule.hhmmString(for: session.schedule.interval)
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
        let schedule = StretchSchedule(interval: settingsStore.cycleLength)
        var session = StretchSession(schedule: schedule)
        session.start(at: startDate)

        now = startDate
        self.session = session
        self.selectedVoiceIdentifier = selectedVoiceIdentifier
        notificationScheduler = NotificationScheduler()
        overlayController = OverlayController()
        self.settingsStore = settingsStore
        voicePlayer = VoicePlayer()

        super.init()

        self.settingsStore.selectedVoiceIdentifier = selectedVoiceIdentifier
        notificationScheduler.requestAuthorization()
        schedulePreBreakNotification()
        startTimer()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(resetAfterWake),
            name: NSWorkspace.didWakeNotification,
            object: nil,
        )
    }

    func validationMessage(for cycleLengthText: String) -> String? {
        if StretchSchedule.interval(fromHHMM: cycleLengthText) == nil {
            "Use HH:MM from 00:10 to 12:00"
        } else {
            nil
        }
    }

    func canApply(cycleLengthText: String, selectedVoiceIdentifier: String) -> Bool {
        StretchSchedule.interval(fromHHMM: cycleLengthText) != nil
            && VoiceOption.option(for: selectedVoiceIdentifier).id == selectedVoiceIdentifier
    }

    func applySettings(cycleLengthText: String, selectedVoiceIdentifier: String) {
        guard let interval = StretchSchedule.interval(fromHHMM: cycleLengthText) else {
            return
        }

        let voiceIdentifier = VoiceOption.option(for: selectedVoiceIdentifier).id
        let date = Date()
        let schedule = StretchSchedule(interval: interval)
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
            startBreak()
        case .breakCompleted:
            voicePlayer.stop()
            overlayController.hide()
            schedulePreBreakNotification()
        }
    }

    private func startBreak() {
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
            notificationScheduler.cancelPreBreakNotification()
            return
        }

        notificationScheduler.schedulePreBreakNotification(before: nextBreakAt)
    }

    @objc private func resetAfterWake() {
        let date = Date()
        var updatedSession = session

        now = date
        updatedSession.reset(at: date)
        session = updatedSession
        voicePlayer.stop()
        overlayController.hide()
        schedulePreBreakNotification()
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
