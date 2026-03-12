import AppKit
import SwiftUI
import Combine

final class FloatingPillWindow: NSPanel {
    private var cancellables = Set<AnyCancellable>()
    private weak var sessionManager: FocusSessionManager?

    init(sessionManager: FocusSessionManager) {
        self.sessionManager = sessionManager

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

        var islandView = DynamicIslandView(sessionManager: sessionManager)
        islandView.onInteractionModeChanged = { [weak self] interactive in
            self?.setInteractive(interactive)
        }

        let centeredView = islandView
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        let hostingView = NSHostingView(rootView: centeredView)
        contentView = hostingView

        positionAtTopCenter()

        sessionManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.positionAtTopCenter()
                let interactive = state == .setup || state == .completed
                self?.setInteractive(interactive)
            }
            .store(in: &cancellables)
    }

    private var interactive = false

    override var canBecomeKey: Bool { interactive }

    private func setInteractive(_ value: Bool) {
        interactive = value
        ignoresMouseEvents = !value
        if value {
            makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            resignKey()
        }
    }

    override func keyDown(with event: NSEvent) {
        // Escape dismisses setup
        if event.keyCode == 53, sessionManager?.state == .setup {
            Task { @MainActor in
                sessionManager?.dismissSetup()
            }
            return
        }
        super.keyDown(with: event)
    }

    func positionAtTopCenter() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        // Large enough for the setup state (the biggest view)
        let windowWidth: CGFloat = 340
        let windowHeight: CGFloat = 210
        let windowFrame = NSRect(
            x: screenFrame.midX - windowWidth / 2,
            y: screenFrame.maxY - windowHeight - 6,
            width: windowWidth,
            height: windowHeight
        )
        setFrame(windowFrame, display: true)
    }
}
