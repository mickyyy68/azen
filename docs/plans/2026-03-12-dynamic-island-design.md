# aZen — Dynamic Island UI Redesign

## Overview

Replace the static floating pill with a shape-shifting Dynamic Island that morphs between a compact capsule (active) and an expanded rounded rectangle (completed). Smooth spring animations between states. Positioned top-center below the menu bar.

## States

### Compact (active/paused) — 120x36pt capsule
- Background: Black 75% opacity over `.ultraThinMaterial`
- Left: 8pt pulsing dot — teal/cyan, pulses opacity 0.4→1.0 on 2s ease-in-out loop, soft glow shadow
- Right: Countdown timer, white, monospaced, semibold
- Paused: Dot turns gray and stops pulsing, timer text dims to 70%
- Corner radius: Fully rounded (capsule)
- Shadow: Black 20%, radius 10, y-offset 3

### Expanded (completed) — 280x80pt rounded rectangle
- Background: Amber/orange 85% opacity over `.ultraThinMaterial`
- Corner radius: 20pt
- Checkmark ring: 28pt diameter, white, 2pt stroke — circle draws in 0.3s, check strokes in 0.2s
- Task name: White, rounded design, medium weight, 1-line max
- "Time's up": White 70% opacity, caption
- "⌘⇧F": White 50% opacity, caption2
- Content vertically stacked, center-aligned

## Animations

- **Appear (idle → active):** Scale 0.3→1.0, opacity 0→1, spring (response: 0.4, damping: 0.7)
- **Morph (active → completed):** Frame 120x36→280x80, capsule→20pt rounded rect, black→amber crossfade, spring (response: 0.5, damping: 0.75). Checkmark draws after morph settles (0.2s delay)
- **Dismiss (any → idle):** Scale→0.3, opacity→0, easeIn 0.25s
- **Pulsing dot:** Opacity 0.4↔1.0, glow radius 3↔8pt, easeInOut 1s repeating
- **Timer digits:** `.numericText()` content transition

## Files Changed

- `PillView.swift` — Full rewrite → `DynamicIslandView`
- `FloatingPillWindow.swift` — Resize window for expanded state, reposition on state change
