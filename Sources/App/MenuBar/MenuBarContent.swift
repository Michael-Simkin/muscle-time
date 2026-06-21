import AppKit
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var model: StretchTimerModel

    var body: some View {
        Text(model.statusText)
        Divider()
        SettingsLink()
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
