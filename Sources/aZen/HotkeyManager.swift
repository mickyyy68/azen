import AppKit
import Carbon.HIToolbox

struct HotkeyConfig {
    var keyCode: UInt16
    var modifiers: NSEvent.ModifierFlags

    static let `default` = HotkeyConfig(
        keyCode: UInt16(kVK_ANSI_X),
        modifiers: [.command, .shift]
    )

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(keyName)
        return parts.joined()
    }

    private var keyName: String {
        // Map common key codes to display names
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        default: return "?"
        }
    }

    private static let keyCodeKey = "hotkeyKeyCode"
    private static let modifiersKey = "hotkeyModifiers"

    func save() {
        UserDefaults.standard.set(Int(keyCode), forKey: HotkeyConfig.keyCodeKey)
        UserDefaults.standard.set(modifiers.rawValue, forKey: HotkeyConfig.modifiersKey)
    }

    static func load() -> HotkeyConfig {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: keyCodeKey) != nil else {
            return .default
        }
        let keyCode = UInt16(defaults.integer(forKey: keyCodeKey))
        let modRaw = UInt(defaults.integer(forKey: modifiersKey))
        return HotkeyConfig(
            keyCode: keyCode,
            modifiers: NSEvent.ModifierFlags(rawValue: modRaw)
        )
    }
}

// Carbon event callback for global hot key — must be a free function (no captures)
private func carbonHotKeyHandler(
    _: EventHandlerCallRef?,
    _: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        manager.onHotkey?()
    }
    return noErr
}

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private(set) var config: HotkeyConfig

    var onHotkey: (() -> Void)?
    var onConfigChanged: (() -> Void)?

    init() {
        self.config = HotkeyConfig.load()
    }

    func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            carbonHotKeyHandler,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(
            signature: OSType(0x615A_656E), // "aZen"
            id: UInt32(1)
        )
        RegisterEventHotKey(
            UInt32(config.keyCode),
            carbonModifiers(from: config.modifiers),
            hotKeyID,
            GetEventDispatcherTarget(),
            OptionBits(0),
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    func update(config newConfig: HotkeyConfig) {
        unregister()
        self.config = newConfig
        newConfig.save()
        register()
        onConfigChanged?()
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        return mods
    }
}
