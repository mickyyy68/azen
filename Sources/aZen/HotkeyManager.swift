import AppKit
import Carbon.HIToolbox

final class HotkeyManager {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    var onHotkey: (() -> Void)?

    func register() {
        // Global monitor for when the app is not focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor for when the app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // consume the event
            }
            return event
        }
    }

    func unregister() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // ⌘⇧F
        let isCommand = event.modifierFlags.contains(.command)
        let isShift = event.modifierFlags.contains(.shift)
        let isF = event.keyCode == UInt16(kVK_ANSI_F)

        if isCommand && isShift && isF {
            onHotkey?()
            return true
        }
        return false
    }
}
