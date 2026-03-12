import SwiftUI
import Combine

@main
struct aZenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All UI is managed by AppDelegate (menu bar + pill window)
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var pillWindow: FloatingPillWindow?
    private let sessionManager = FocusSessionManager()
    private let hotkeyManager = HotkeyManager()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupPillWindow()
        setupHotkey()
        observeSessionState()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scope", accessibilityDescription: "aZen")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 280)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopover(sessionManager: sessionManager)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Pill Window

    private func setupPillWindow() {
        pillWindow = FloatingPillWindow(sessionManager: sessionManager)
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyManager.onHotkey = { [weak self] in
            Task { @MainActor in
                self?.togglePopover()
            }
        }
        hotkeyManager.register()
    }

    // MARK: - State Observation

    private func observeSessionState() {
        sessionManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .active, .paused, .completed:
                    self.pillWindow?.positionAtTopCenter()
                    self.pillWindow?.orderFront(nil)
                case .idle:
                    self.pillWindow?.orderOut(nil)
                }
                self.updateStatusIcon(state: state)
            }
            .store(in: &cancellables)
    }

    private func updateStatusIcon(state: SessionState) {
        let symbolName = state == .idle ? "scope" : "scope"
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        var image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "aZen")
        if state != .idle {
            let filledConfig = config.applying(.init(paletteColors: [.controlAccentColor]))
            image = image?.withSymbolConfiguration(filledConfig)
        }
        statusItem.button?.image = image
    }
}
