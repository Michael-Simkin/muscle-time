import SwiftUI

@main
struct StretchBlockerApp: App {
    var body: some Scene {
        MenuBarExtra("StretchBlocker", systemImage: "figure.flexibility") {
            MenuBarContent()
        }

        Settings {
            SettingsView()
        }
    }
}
