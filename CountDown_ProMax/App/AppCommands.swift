import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Countdown") {
                NotificationCenter.default.post(name: .createNewCountdown, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandMenu("Share") {
            Button("Copy Top 6 Summaries") {
                NotificationCenter.default.post(name: .copyTopSummaries, object: nil)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }

        CommandMenu("Panel") {
            Button("Toggle Floating Panel") {
                FloatingPanelManager.shared.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])

            Divider()

            Button("Always on Top") {
                FloatingPanelManager.shared.setMode(.alwaysOnTop)
            }

            Button("Normal Window") {
                FloatingPanelManager.shared.setMode(.normal)
            }
        }
    }
}

extension Notification.Name {
    static let createNewCountdown = Notification.Name("createNewCountdown")
    static let copyTopSummaries = Notification.Name("copyTopSummaries")
    static let copiedToClipboard = Notification.Name("copiedToClipboard")
}
