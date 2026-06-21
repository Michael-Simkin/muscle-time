import AppKit
import SwiftUI

@MainActor
final class OverlayController {
    private var actions: OverlayActions?
    private var screenObserver: ScreenObserver?
    private var windows: [OverlayWindow] = []

    init() {
        screenObserver = ScreenObserver { [weak self] in
            self?.rebuildWindowsForCurrentScreens()
        }
    }

    func show(
        onDone: @escaping @MainActor () -> Void,
        onPostpone: @escaping @MainActor () -> Void,
    ) {
        actions = OverlayActions(onDone: onDone, onPostpone: onPostpone)
        rebuildWindowsForCurrentScreens()
    }

    func hide() {
        actions = nil

        let closingWindows = windows
        windows = []

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            for window in closingWindows {
                window.animator().alphaValue = 0
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))

            for window in closingWindows {
                window.orderOut(nil)
            }
        }
    }

    private func rebuildWindowsForCurrentScreens() {
        for window in windows {
            window.orderOut(nil)
        }

        guard let actions else {
            windows = []
            return
        }

        windows = NSScreen.screens.map { screen in
            let rootView = StretchOverlayView(
                onDone: actions.onDone,
                onPostpone: actions.onPostpone,
            )
            let hostingView = NSHostingView(rootView: rootView)
            hostingView.frame = screen.frame
            hostingView.autoresizingMask = [.width, .height]

            return OverlayWindow(screen: screen, contentView: hostingView)
        }

        for window in windows {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

private struct OverlayActions {
    let onDone: @MainActor () -> Void
    let onPostpone: @MainActor () -> Void
}

private struct StretchOverlayView: View {
    let onDone: @MainActor () -> Void
    let onPostpone: @MainActor () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.94),
                    Color(red: 0.10, green: 0.08, blue: 0.16).opacity(0.96),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Muscle Time!")
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Stretch now. Click Done to close, or postpone by 5 minutes.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.82))

                HStack(spacing: 16) {
                    Button("Done") {
                        onDone()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)

                    Button("Postpone 5 min") {
                        onPostpone()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(48)
        }
    }
}
