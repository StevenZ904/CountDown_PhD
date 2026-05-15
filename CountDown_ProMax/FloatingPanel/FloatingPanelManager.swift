import AppKit
import SwiftUI
import SwiftData

@Observable
@MainActor
final class FloatingPanelManager {
    static let shared = FloatingPanelManager()

    enum PanelMode: String, CaseIterable {
        case alwaysOnTop
        case normal
        case hidden

        var displayName: String {
            switch self {
            case .alwaysOnTop: "Always on Top"
            case .normal: "Normal Window"
            case .hidden: "Hidden"
            }
        }
    }

    private(set) var panel: FloatingPanel?
    private(set) var modelContainer: ModelContainer?
    var panelMode: PanelMode = .normal {
        didSet { persistMode() }
    }
    var isVisible: Bool { panel?.isVisible ?? false }

    private init() {
        // Restore saved mode
        if let raw = UserDefaults.standard.string(forKey: "floatingPanelMode"),
           let mode = PanelMode(rawValue: raw) {
            panelMode = mode
        }
    }

    func show(modelContainer: ModelContainer) {
        if panel == nil {
            let defaultFrame = NSRect(x: 100, y: 100, width: 280, height: 400)
            let newPanel = FloatingPanel(contentRect: defaultFrame)

            let hostingView = NSHostingView(
                rootView: FloatingPanelContentView()
                    .modelContainer(modelContainer)
            )
            newPanel.contentView = hostingView

            // Restore saved frame
            if let frameString = UserDefaults.standard.string(forKey: "floatingPanelFrame") {
                let frame = NSRectFromString(frameString)
                if frame.width > 0 && frame.height > 0 {
                    newPanel.setFrame(frame, display: false)
                }
            }

            // Save frame on move/resize
            NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification,
                object: newPanel,
                queue: .main
            ) { _ in
                MainActor.assumeIsolated {
                    FloatingPanelManager.shared.persistFrame()
                }
            }
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification,
                object: newPanel,
                queue: .main
            ) { _ in
                MainActor.assumeIsolated {
                    FloatingPanelManager.shared.persistFrame()
                }
            }

            self.panel = newPanel
        }

        updateLevel()
        panel?.orderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func toggle() {
        if isVisible {
            hide()
        } else if let container = modelContainer {
            show(modelContainer: container)
        }
    }

    func setMode(_ mode: PanelMode) {
        panelMode = mode
        if mode == .hidden {
            hide()
        } else {
            updateLevel()
            if !isVisible, let container = modelContainer {
                show(modelContainer: container)
            }
        }
    }

    // MARK: - Private

    private func updateLevel() {
        switch panelMode {
        case .alwaysOnTop:
            panel?.level = .floating
        case .normal:
            panel?.level = .normal
        case .hidden:
            panel?.orderOut(nil)
        }
    }

    private func persistMode() {
        UserDefaults.standard.set(panelMode.rawValue, forKey: "floatingPanelMode")
    }

    private func persistFrame() {
        guard let frame = panel?.frame else { return }
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: "floatingPanelFrame")
    }

}
