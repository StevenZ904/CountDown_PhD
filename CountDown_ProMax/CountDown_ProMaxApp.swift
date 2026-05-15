import SwiftUI
import SwiftData
import os

private let logger = Logger(subsystem: "CountDown_ProMax", category: "App")

@main
struct CountDown_ProMaxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    let usingCloudKit: Bool

    init() {
        do {
            let result = try ModelContainerFactory.create()
            modelContainer = result.container
            usingCloudKit = result.isCloudKitEnabled
        } catch {
            // All attempts in factory failed — fall back to plain local storage
            logger.error("❌ All ModelContainer attempts failed: \(error.localizedDescription)")
            logger.warning("⚠️ Falling back to bare local-only storage.")
            usingCloudKit = false
            do {
                let fallbackConfig = ModelConfiguration(
                    "CountDown_ProMax",
                    schema: Schema([Countdown.self]),
                    cloudKitDatabase: .none
                )
                modelContainer = try ModelContainer(
                    for: Schema([Countdown.self]),
                    configurations: fallbackConfig
                )
            } catch {
                fatalError("Failed to create even fallback ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleURL(url)
                }
                .onAppear {
                    FloatingPanelManager.shared.configure(modelContainer: modelContainer)
                    if usingCloudKit {
                        logger.info("☁️ iCloud sync is ACTIVE")
                    } else {
                        logger.warning("📦 Running in LOCAL-ONLY mode (no iCloud)")
                    }
                }
        }
        .modelContainer(modelContainer)
        .commands {
            AppCommands()
        }
    }

    private func handleURL(_ url: URL) {
        // URL format: countdownpromax://open?id=<UUID>
        guard url.scheme == AppConstants.urlScheme else { return }

        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
            window.makeKeyAndOrderFront(nil)
        }

        // If a specific countdown ID is provided, navigate to it
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let idString = components.queryItems?.first(where: { $0.name == "id" })?.value {
            NotificationCenter.default.post(
                name: .navigateToCountdown,
                object: nil,
                userInfo: ["countdownID": idString]
            )
        }
    }
}
