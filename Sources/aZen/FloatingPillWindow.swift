import AppKit
import SwiftUI

final class FloatingPillWindow: NSPanel {
    init(sessionManager: FocusSessionManager) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let pillView = PillView(sessionManager: sessionManager)
        let hostingView = NSHostingView(rootView: pillView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        contentView = hostingView
        positionAtTopCenter()
    }

    func positionAtTopCenter() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        // Size the window to fit content
        let idealSize = contentView?.fittingSize ?? CGSize(width: 400, height: 50)
        let windowFrame = NSRect(
            x: screenFrame.midX - idealSize.width / 2,
            y: screenFrame.maxY - idealSize.height - 20,
            width: idealSize.width,
            height: idealSize.height
        )
        setFrame(windowFrame, display: true)
    }
}
