import AppKit
import Carbon.HIToolbox

final class ShortcutRecorderPanel: NSPanel {
    private var localMonitor: Any?
    var onShortcutCaptured: ((HotkeyConfig) -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 120),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        title = "Change Shortcut"
        isFloatingPanel = true
        level = .floating
        center()
        setupContent()
    }

    private func setupContent() {
        let label = NSTextField(labelWithString: "Press your desired shortcut…")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let hint = NSTextField(labelWithString: "Use ⌘, ⇧, ⌃, ⌥ + a key. Press Esc to cancel.")
        hint.font = .systemFont(ofSize: 12)
        hint.textColor = .secondaryLabelColor
        hint.alignment = .center
        hint.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: contentRect(forFrameRect: frame))
        container.addSubview(label)
        container.addSubview(hint)
        contentView = container

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -10),
            hint.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            hint.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
        ])
    }

    func beginCapture() {
        // LSUIElement apps can't become active — temporarily switch policy so the panel can receive key events
        NSApp.setActivationPolicy(.accessory)
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            if event.keyCode == UInt16(kVK_Escape) {
                self.endCapture()
                return nil
            }

            let relevantModifiers: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
            let mods = event.modifierFlags.intersection(relevantModifiers)

            // Require at least ⌘ or ⌃
            guard mods.contains(.command) || mods.contains(.control) else {
                return nil
            }

            let config = HotkeyConfig(keyCode: event.keyCode, modifiers: mods)
            self.onShortcutCaptured?(config)
            self.endCapture()
            return nil
        }
    }

    private func endCapture() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        orderOut(nil)
        NSApp.setActivationPolicy(.prohibited)
    }
}
