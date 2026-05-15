# CountDown ProMax

A macOS countdown manager built with SwiftUI, SwiftData, and WidgetKit. Track deadlines, conference submissions, and milestones — all synced across your Macs via iCloud.

## Features

### Countdown Management
- Create countdowns with date picker or natural duration input ("3d 4h 10m")
- Pin important countdowns to keep them at the top
- Drag-to-reorder for priority ranking
- Color-coded cards with live-updating countdown text
- Quick adjustments: +10m, +1h, +1d, End of Day, End of Week

### Conference Deadline Support
- **Anywhere on Earth (AoE)** — the standard for academic deadlines
- **Specific Time Zone** — pick from common zones or the full system list
- Local time conversion displayed alongside the original deadline

### Milestones
- Add checkpoint milestones within a countdown (e.g., "Draft done", "Experiments", "Camera-ready")
- Quick-add presets for common academic milestones
- Track completion status and see overdue warnings

### Desktop Widgets
- **Single Countdown** — small widget with a live-updating timer
- **Multi Countdown** — small (2×2 grid, 4 items) or medium (5-item list)
- Widgets show countdowns by priority rank (pinned first, then drag order)
- Deep-link tap to open the countdown in the app

### Floating Panel
- Always-on-top panel showing up to 6 countdowns
- Stays visible across all Spaces and fullscreen apps
- Toggle with Cmd+Shift+P

### Notifications
- 5 preset rules: at deadline, 5m / 15m / 1h / 1 day before
- Per-countdown notification configuration
- Banners with sound, even when the app is in the foreground

### iCloud Sync
- All countdowns sync across Macs via CloudKit
- Graceful fallback to local-only storage if iCloud is unavailable

### Quick Share
- Copy a countdown summary to clipboard (Cmd+Shift+C for top 6)
- Context menu copy on individual countdowns
- Format includes timezone info when applicable

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+N | New Countdown |
| Cmd+Shift+P | Toggle Floating Panel |
| Cmd+Shift+C | Copy Top 6 Summaries |

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16+ to build
- iCloud account for sync (optional)

## Architecture

- **SwiftUI** + **SwiftData** with CloudKit integration
- **WidgetKit** for desktop widgets
- **Swift 6** with MainActor default isolation
- Data shared between app and widgets via App Group UserDefaults (snapshot bridge)
- NSPanel-based floating window (non-activating, utility style)

## Building

1. Open `CountDown_ProMax.xcodeproj` in Xcode
2. Select the `CountDown_ProMax` scheme
3. Build and run (Cmd+R)

To test widgets, also build the `CountDown_ProMax_WidgetsExtension` target, then add widgets via right-click desktop → Edit Widgets → search "Countdown".

## License

All rights reserved.
