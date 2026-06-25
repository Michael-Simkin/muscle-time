import AppKit
import MuscleCore
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
            let rootView = MuscleTimeOverlayView(
                onDone: actions.onDone,
                onPostpone: actions.onPostpone,
            )
            let hostingView = NSHostingView(rootView: rootView)
            hostingView.frame = screen.frame
            hostingView.autoresizingMask = [.width, .height]

            return OverlayWindow(screen: screen, contentView: hostingView)
        }

        // Activate so the overlay can become key and respond to its keyboard
        // shortcuts; without this an accessory app's borderless window stays
        // unfocused.
        NSApplication.shared.activate(ignoringOtherApps: true)

        for window in windows {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

private struct OverlayActions {
    let onDone: @MainActor () -> Void
    let onPostpone: @MainActor () -> Void
}

private struct MuscleTimeOverlayView: View {
    let onDone: @MainActor () -> Void
    let onPostpone: @MainActor () -> Void

    @State private var selectedExercise: Exercise?
    @State private var soundPlayer = SoundEffectPlayer()

    private var subtitle: String {
        if let selectedExercise {
            "Your move: \(selectedExercise.displayName)! Do it, then click Done."
        } else {
            "Spin the wheel to pick your exercise."
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.07, blue: 0.20).opacity(0.97),
                    Color(red: 0.20, green: 0.08, blue: 0.24).opacity(0.97),
                    Color(red: 0.06, green: 0.05, blue: 0.12).opacity(0.97),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing,
            )
            .ignoresSafeArea()

            // Soft brand-colored glow behind the card.
            RadialGradient(
                colors: [Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.45), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 460,
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text("Muscle Time!")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(maxWidth: 520)
                }

                SpinWheelView { exercise in
                    selectedExercise = exercise
                    soundPlayer.play(resource: "SoundExerciseSelected", fileExtension: "mp3")
                    soundPlayer.play(resource: exercise.announcementResource, fileExtension: "mp3")
                }

                HStack(spacing: 16) {
                    Button("Done") {
                        onDone()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedExercise == nil)

                    Button("Postpone 5 min") {
                        onPostpone()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                }
                .tint(Color(red: 0.62, green: 0.40, blue: 0.95))
                .padding(.top, 4)
            }
            .padding(.vertical, 48)
            .padding(.horizontal, 64)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1),
                    ),
            )
            .shadow(color: .black.opacity(0.45), radius: 40, y: 16)
        }
    }
}
