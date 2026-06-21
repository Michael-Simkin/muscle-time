import SwiftUI

@main
struct StretchBlockerApp: App {
    @StateObject private var model = StretchTimerModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(model: model)
        } label: {
            HStack(spacing: 4) {
                Image("MenuBarFlexArm")
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(model.menuBarRemainingText)
                    .monospacedDigit()
            }
        }

        Settings {
            SettingsView(model: model)
        }
    }
}
