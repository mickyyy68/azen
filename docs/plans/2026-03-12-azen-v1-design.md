# aZen — v1 Design

## What is aZen?

aZen is a native macOS menu bar app that helps developers stay focused by displaying a floating pill on screen showing their current task and a countdown timer. It's a visual anchor — a constant, gentle reminder of what you should be doing right now.

## Core Loop

1. You trigger a focus session (menu bar or `⌘⇧F`)
2. You type a task and pick a duration
3. A floating pill appears at top-center of your screen, always on top
4. When time's up, the pill prompts: "Time's up — ⌘⇧F"
5. You make a conscious decision about what's next

**What it is not:** A task manager, a pomodoro app with stats, or a productivity tracker. It's a single-task focus tool. One task. One timer. On screen.

## Architecture

**App type:** macOS menu bar app (no Dock icon). SwiftUI + AppKit.

### Components

- **aZenApp** — App entry point. `MenuBarExtra` for the menu bar popover. No main window.
- **FloatingPillWindow** — An `NSPanel` (always on top, non-activating, click-through). Positioned at top-center of the screen. Hosts a SwiftUI view.
- **PillView** — SwiftUI view showing task text + timer countdown. Read-only.
- **MenuBarPopover** — SwiftUI view inside the menu bar dropdown. Task input, presets, controls.
- **FocusSessionManager** — ObservableObject that owns the session state: task, duration, time remaining, status. Drives both the pill and the menu bar UI.
- **HotkeyManager** — Registers global `⌘⇧F` shortcut to open the menu bar popover.

### File Structure

```
aZen/
├── aZen.xcodeproj
├── aZen/
│   ├── aZenApp.swift
│   ├── FocusSessionManager.swift
│   ├── HotkeyManager.swift
│   ├── FloatingPillWindow.swift
│   ├── PillView.swift
│   ├── MenuBarPopover.swift
│   ├── Assets.xcassets/
│   └── Info.plist
```

## The Floating Pill

### Appearance

- Rounded capsule shape, ~400pt wide, ~50pt tall
- Semi-transparent dark background with vibrancy (macOS material blur)
- Task text on the left, timer on the right
- System font, white text
- Subtle shadow to lift it off the screen

### Positioning

- Top-center of the main screen, ~20px below the menu bar
- Always above all windows (floating panel level)
- Non-activating — clicking through it hits whatever's underneath
- Cannot be dragged or interacted with

### Timer States

- **Active** — Dark/neutral background. Timer counts down (`23:45`).
- **Completed** — Background shifts to warm amber/orange. Timer shows `0:00`. Text shows "Time's up — ⌘⇧F".

## Menu Bar Popover

### Idle State (no session)

- Text field: "What are you working on?"
- Preset duration buttons: `15m` `25m` `45m` `60m`
- Custom duration input field
- "Start Focus" button

### Active State (session running)

- Shows current task + time remaining
- Buttons: Pause / Resume, End Session

### Completed State (timer finished)

- Shows "Time's up!" with the task name
- Three buttons:
  - **Continue** — Same task, pick new duration
  - **New Task** — Clear and start fresh
  - **Done** — Dismiss pill, back to idle

## Interaction

- **Menu bar icon** — Click to open popover. Icon changes when session is active.
- **Global hotkey (`⌘⇧F`)** — Opens the menu bar popover from anywhere. Primary way to start sessions and respond to timer completion.
- **Pill** — Purely visual. Read-only. No interaction. Clicks pass through.

## Technical Details

- **State management:** `FocusSessionManager` as `ObservableObject`. All state flows from here.
- **Timer:** `Timer.publish(every: 1, on: .main, in: .common)`
- **Floating window:** `NSPanel` with `.floating` level, `ignoresMouseEvents = true`
- **No Dock icon:** `LSUIElement = YES` in Info.plist
- **No persistence:** Sessions are ephemeral in v1
- **Target:** macOS 14+ (Sonoma)
