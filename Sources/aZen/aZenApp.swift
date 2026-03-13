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
    private var openMenuItem: NSMenuItem?
    private var shortcutPanel: ShortcutRecorderPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.applicationIconImage = makeAppIcon()
        setupStatusItem()
        setupPillWindow()
        setupHotkey()
        observeSessionState()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = makeMenuBarIcon()
        }

        let menu = NSMenu()
        let openItem = NSMenuItem(title: openMenuTitle(), action: #selector(openIsland), keyEquivalent: "")
        menu.addItem(openItem)
        openMenuItem = openItem
        menu.addItem(withTitle: "Change Shortcut…", action: #selector(changeShortcut), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        statusItem.menu = menu
    }

    private func openMenuTitle() -> String {
        "Open aZen (\(hotkeyManager.config.displayString))"
    }

    @objc private func openIsland() {
        toggleIsland()
    }

    @objc private func changeShortcut() {
        let panel = ShortcutRecorderPanel()
        panel.onShortcutCaptured = { [weak self] config in
            self?.hotkeyManager.update(config: config)
        }
        panel.beginCapture()
        shortcutPanel = panel
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
        hotkeyManager.onConfigChanged = { [weak self] in
            Task { @MainActor in
                self?.openMenuItem?.title = self?.openMenuTitle() ?? "Open aZen"
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
        if let button = statusItem.button {
            button.image = makeMenuBarIcon()
            button.contentTintColor = (state != .idle && state != .setup)
                ? .controlAccentColor
                : nil
        }
    }

    // MARK: - Icon Rendering

    private func makeMenuBarIcon() -> NSImage {
        let text = "aZ" as NSString
        let font = NSFont.systemFont(ofSize: 14, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        let size = text.size(withAttributes: attrs)
        let image = NSImage(size: size, flipped: false) { rect in
            text.draw(in: rect, withAttributes: attrs)
            return true
        }
        image.isTemplate = true
        return image
    }

    private func makeAppIcon() -> NSImage {
        let size: CGFloat = 512
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let bgPath = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
            NSColor.black.setFill()
            bgPath.fill()

            let text = "aZ" as NSString
            let font = NSFont.systemFont(ofSize: size * 0.42, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = NSRect(
                x: (size - textSize.width) / 2,
                y: (size - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
            return true
        }
        return image
    }
}
