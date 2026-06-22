import AppKit
import Combine

// swiftlint:disable:next unused_import
import OSLog
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private static let autosaveName = "MuscleTimeMenuBarItem"

    private let logger = Logger(subsystem: "com.michael.MuscleTime", category: "StatusItem")
    private let model: MuscleTimeTimerModel
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var screenChangeObserver: NSObjectProtocol?
    private var appResignObserver: NSObjectProtocol?
    private var modelCancellable: AnyCancellable?

    init(model: MuscleTimeTimerModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()

        super.init()

        installStatusItem()
        bindModel()
        observeScreenChanges()
        observeApplicationState()
    }

    private func installStatusItem() {
        statusItem.autosaveName = Self.autosaveName
        statusItem.behavior = []
        statusItem.isVisible = true

        if let button = statusItem.button {
            button.image = Self.menuBarImage()
            button.imagePosition = .imageLeading
            button.imageHugsTitle = true
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.toolTip = model.statusText
            button.target = self
            button.action = #selector(togglePopover)
            button.cell?.lineBreakMode = .byClipping
        } else {
            logger.error("Status item installed without a button.")
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: StatusBarPopoverContent(model: model))

        updateStatusItem()
        logStatusItemState(reason: "installed")
    }

    private func bindModel() {
        modelCancellable = model.objectWillChange.sink { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateStatusItem()
            }
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = model.menuBarRemainingText
        button.toolTip = model.statusText
        statusItem.length = NSStatusItem.variableLength
    }

    private func observeScreenChanges() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: nil,
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.logStatusItemState(reason: "screen-change")
            }
        }
    }

    private func observeApplicationState() {
        appResignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: nil,
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopover()
            }
        }
    }

    private func logStatusItemState(reason: String) {
        let isVisible = statusItem.isVisible
        let hasButton = statusItem.button != nil
        let title = model.menuBarRemainingText
        logger.notice(
            """
            Status item state. reason=\(reason, privacy: .public) \
            isVisible=\(isVisible, privacy: .public) \
            hasButton=\(hasButton, privacy: .public) \
            title=\(title, privacy: .public)
            """,
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
            return
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    private static func menuBarImage() -> NSImage {
        if let image = NSImage(named: "MenuBarFlexArm") {
            image.size = NSSize(width: 16, height: 16)
            image.isTemplate = true
            return image
        }

        if let image = NSImage(systemSymbolName: "dumbbell", accessibilityDescription: "Muscle Time") {
            image.isTemplate = true
            return image
        }

        let image = NSImage(size: NSSize(width: 14, height: 14), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2)).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}

private struct StatusBarPopoverContent: View {
    @ObservedObject var model: MuscleTimeTimerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.statusText)
                .font(.headline)

            Divider()

            SettingsView(model: model)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 320)
    }
}
