import AppKit

/// A lightweight NSPanel subclass that supports always-on-top, non-activating behavior,
/// and can persist across spaces — the macOS signature feature.
class FloatingPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .windowBackgroundColor
        isOpaque = false
        hasShadow = true
        minSize = NSSize(width: 220, height: 120)
        level = .normal
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
