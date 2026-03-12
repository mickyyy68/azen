import SwiftUI
import Combine

@main
struct aZenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var pillWindow: FloatingPillWindow?
    private let sessionManager = FocusSessionManager()
    private let hotkeyManager = HotkeyManager()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPillWindow()
        setupHotkey()
        observeSessionState()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "scope", accessibilityDescription: "aZen")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Open aZen (⌘⇧F)", action: #selector(openIsland), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func openIsland() {
        toggleIsland()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Pill Window

    private func setupPillWindow() {
        pillWindow = FloatingPillWindow(sessionManager: sessionManager)
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyManager.onHotkey = { [weak self] in
            Task { @MainActor in
                self?.toggleIsland()
            }
        }
        hotkeyManager.register()
    }

    private func toggleIsland() {
        switch sessionManager.state {
        case .idle:
            sessionManager.showSetup()
        case .setup:
            sessionManager.dismissSetup()
        case .active, .paused:
            // During focus, hotkey does nothing (or could pause — keep simple for v1)
            break
        case .completed:
            // Already showing completed state, no action needed
            break
        }
    }

    // MARK: - State Observation

    private func observeSessionState() {
        sessionManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .setup, .active, .paused, .completed:
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
        var image = NSImage(systemSymbolName: "scope", accessibilityDescription: "aZen")
        if state != .idle && state != .setup {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                .applying(.init(paletteColors: [.controlAccentColor]))
            image = image?.withSymbolConfiguration(config)
        }
        statusItem.button?.image = image
    }
}
