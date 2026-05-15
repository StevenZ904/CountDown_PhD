# CountDown_ProMax — MVP Technical Document

## Overview

**Version:** v1.2 — Implemented
**Platform:** macOS (Sonoma 14.0+)
**Framework:** SwiftUI + SwiftData + WidgetKit + CloudKit
**Language:** Swift 6 (MainActor default isolation)

CountDown_ProMax is a macOS countdown manager. Users create countdowns with flexible time-entry methods (date picker or duration text), view them in a sidebar-filtered list, display up to 6 on their desktop via WidgetKit widgets, and keep important countdowns visible in a floating panel (NSPanel) that stays on top of other windows. Supports conference deadline time zones (AoE / explicit TZ with local conversion), per-countdown milestones for pacing work, and quick-share clipboard copy for Slack/email. All data syncs across Macs via iCloud (SwiftData + CloudKit).

---

## Decisions Made

| Decision | Choice |
|----------|--------|
| Default deadline | Next full hour |
| Platform | macOS only (iOS deferred) |
| Floating panel scope | Multi (up to 6 countdowns) |
| Storage | SwiftData + CloudKit (offline local + iCloud sync) |
| Ending Soon threshold | 72 hours |
| Widget selection | Pinned first, then by priority rank (drag order) |
| Overdue repeat reminders | Deferred to v1.2 |

---

## Architecture

```
CountDown_ProMaxApp (@main)
├── ModelContainer (SwiftData + CloudKit + App Group)
├── AppDelegate (notifications, CloudKit change observer)
├── AppCommands (menu bar: Cmd+N, Cmd+Shift+P, Cmd+Shift+C)
├── ContentView (NavigationSplitView root)
│   ├── SidebarView (smart filters)
│   └── CountdownListView (filtered, sorted cards)
│       └── CountdownCardView → LiveCountdownText (TimelineView)
├── CountdownEditSheet (create/edit modal)
│   ├── DateTimePickerSection | DurationInputSection
│   ├── DeadlineSemanticsSection (timezone/AoE picker)
│   ├── DisplaySettingsSection
│   ├── ColorPickerSection
│   ├── MilestonesSection (milestone CRUD)
│   └── NotificationRulesSection
├── FloatingPanelManager → FloatingPanel (NSPanel)
│   └── FloatingPanelContentView (up to 6 countdowns)
└── WidgetDataBridge → App Group UserDefaults
    └── CountDown_ProMax_Widgets (separate target)
        ├── SingleCountdownWidget (small/medium/large)
        └── MultiCountdownWidget (medium/large, up to 6)
```

---

## Project Structure

```
CountDown_ProMax/
├── CountDown_ProMaxApp.swift          App entry, ModelContainer, URL handler
├── ContentView.swift                  Root NavigationSplitView + widget sync
├── Info.plist                         URL scheme registration (countdownpromax://)
├── CountDown_ProMax.entitlements      iCloud, Push Notifications, App Groups
│
├── Models/
│   ├── Enums.swift                    CountdownMode, UnitMode, OverdueBehavior,
│   │                                  ColorToken, FixedUnit, SortOption, SmartViewFilter,
│   │                                  DeadlineSemantics
│   ├── NotificationRule.swift         Codable struct + 5 presets
│   ├── Milestone.swift               Codable struct (stored as JSON in Countdown)
│   └── Countdown.swift               @Model class (CloudKit-compatible raw strings)
│
├── Shared/
│   ├── AppConstants.swift             IDs: App Group, CloudKit, URL scheme, widget kinds
│   ├── ModelContainerFactory.swift    create() for app, createForWidget() for extension
│   ├── CountdownFormatter.swift       Auto/Fixed/Mixed formatting + share summary
│   ├── DurationParser.swift           Regex parser: "3d 4h 10m" → TimeInterval
│   └── WidgetDataBridge.swift         Snapshot bridge via App Group UserDefaults
│
├── Services/
│   ├── NotificationService.swift      UNNotification schedule/cancel/reconcile
│   └── CountdownRepository.swift      CRUD + filter/sort helpers
│
├── App/
│   ├── AppDelegate.swift              Notification delegate, CloudKit observer
│   └── AppCommands.swift              Menu: New Countdown, Panel toggle, Share
│
├── Views/
│   ├── MainWindow/
│   │   ├── SidebarView.swift          Smart filters with count badges
│   │   ├── CountdownListView.swift    Filtered list + context menus
│   │   ├── CountdownCardView.swift    Color strip + title + TZ badge + milestone + live text
│   │   └── EmptyStateView.swift       Per-filter empty states
│   ├── Detail/
│   │   ├── CountdownEditSheet.swift   Create/edit form (480×700)
│   │   ├── DateTimePickerSection.swift
│   │   ├── DurationInputSection.swift
│   │   ├── DeadlineSemanticsSection.swift  TZ/AoE picker + local conversion
│   │   ├── DisplaySettingsSection.swift
│   │   ├── ColorPickerSection.swift
│   │   ├── MilestonesSection.swift    Milestone CRUD + quick-add presets
│   │   └── NotificationRulesSection.swift
│   └── Shared/
│       └── LiveCountdownText.swift    TimelineView (1s near deadline, 10s otherwise)
│
├── FloatingPanel/
│   ├── FloatingPanelController.swift  NSPanel subclass (non-activating, utility)
│   ├── FloatingPanelManager.swift     @Observable singleton, UserDefaults persistence
│   └── FloatingPanelContentView.swift SwiftUI: up to 6 rows + milestones + copy
│
CountDown_ProMax_Widgets/
├── CountDown_ProMax_WidgetsBundle.swift
├── CountDown_ProMax_Widgets.swift     Both widgets, providers, snapshot model, formatting
├── CountDown_ProMax_WidgetsExtension.entitlements
└── Info.plist
```

---

## Data Model

### Countdown (@Model, SwiftData)

All enum fields stored as raw `String` for CloudKit compatibility. Computed properties provide type-safe access.

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| id | UUID | auto | |
| title | String | "New Countdown" | Required, validated non-empty |
| deadline | Date | next full hour | Absolute date |
| modeRaw | String | "fixedDeadline" | fixedDeadline, durationToDeadline |
| colorRaw | String | "blue" | 9 options: red, orange, yellow, green, teal, blue, indigo, purple, pink |
| unitModeRaw | String | "auto" | auto, fixed, mixed |
| fixedUnitRaw | String? | nil | years, months, days, hours, minutes, seconds |
| showSeconds | Bool | false | |
| pinned | Bool | false | |
| orderIndex | Double | auto-increment | For manual sort |
| tags | [String] | [] | Stored as Codable array |
| notes | String? | nil | |
| overdueBehaviorRaw | String | "showOverdue" | showOverdue, freezeAtZero |
| notificationRulesData | Data? | nil | JSON-encoded [NotificationRule] |
| deadlineSemanticsRaw | String | "local" | local, timeZone, aoe |
| deadlineTimeZoneID | String? | nil | e.g., "America/New_York"; set when semantics is timeZone |
| milestonesData | Data? | nil | JSON-encoded [Milestone] |
| createdAt | Date | .now | |
| updatedAt | Date | .now | |

### Milestone (Codable struct, stored as JSON in Countdown)

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| title | String | e.g., "Draft done", "Experiments" |
| date | Date | Absolute date for this checkpoint |
| isDone | Bool | Toggled by user |

### NotificationRule (Codable struct, stored as JSON in Countdown)

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| type | RuleType | atTime, beforeTime |
| offsetSeconds | Int | 0 = at deadline, 300 = 5m before, etc. |

**Built-in presets:** At deadline (0s), 5 min (300s), 15 min (900s), 1 hour (3600s), 1 day (86400s)

### CountdownSnapshot (Codable, for widget bridge)

Lightweight value type mirroring essential Countdown fields. Written to App Group UserDefaults by the main app, read by the widget extension. Includes `deadlineSemanticsRaw`, `deadlineTimeZoneID`, `nextMilestoneTitle`, and `nextMilestoneDate` for timezone badge and milestone display in widgets.

---

## Implemented Features

### Countdown CRUD
- **Create:** + button or Cmd+N. Sheet form with title, deadline, display settings, color, notifications, pin, notes.
- **Edit:** Double-click a card or context menu → Edit. Same sheet, pre-populated.
- **Delete:** Context menu → Delete, or red Delete button in edit sheet. Cancels associated notifications.
- **Pin/Unpin:** Context menu toggle. Pinned items appear first in all views and widgets.

### Time Entry
- **Date & Time picker:** Stepper-style date picker for exact deadline selection.
- **Duration input:** Text field parsing "3d 4h 10m" format. Deadline computed as `Date.now + duration` at the moment of save (not at input time). Preview shows static formatted duration, not a drifting live countdown.
- **Quick adjustments:** +10m, +1h, +1d, End of Day (11:59 PM), End of Week (11:59 PM Sunday). In duration mode, these adjust the duration value; in date mode, they adjust the deadline directly.

### Display Modes
- **Auto:** Two largest meaningful units (e.g., "3d 4h left")
- **Fixed:** Single unit with decimal precision (e.g., "3.5 days left", "84.0 hours left")
- **Mixed:** All non-zero units (e.g., "3d 4h 23m left")
- **Show seconds toggle:** Adds seconds to display; also increases update frequency to 1s
- **Overdue:** "Overdue by 1h 12m" (showOverdue) or "0s" (freezeAtZero)
- **All non-overdue displays end with " left"**

### Smart Views (Sidebar)
- **All:** Every countdown, with count badge
- **Pinned:** Only pinned countdowns
- **Ending Soon:** Deadline within 72 hours and not yet overdue
- **Overdue:** Deadline in the past

### Sorting & Priority Ranking
- **Soonest:** By deadline ascending, pinned items first
- **Manual:** By orderIndex (priority rank), pinned items first
- **Title:** Alphabetical (case-insensitive)
- **Drag-to-reorder:** Users drag rows in the list to set priority rank. Auto-switches to Manual sort on drag. The `orderIndex` field stores the rank and syncs via CloudKit.
- **Priority determines widget/panel selection:** Widgets and floating panel show countdowns by priority rank (pinned first, then by orderIndex), not by soonest deadline.

### Live Updates
- `LiveCountdownText` uses `TimelineView(.periodic)`:
  - **1-second updates:** When showSeconds enabled, within 5 minutes of deadline, or overdue
  - **10-second updates:** Default for longer countdowns
- Numeric text content transitions for smooth digit changes

### iCloud Sync
- SwiftData `ModelContainer` with `.cloudKitDatabase: .automatic`
- App Group shared store at `group.sz904.CountDown-ProMax`
- CloudKit container: `iCloud.sz904.CountDown-ProMax`
- Observes `NSPersistentStoreRemoteChangeNotification` to refresh widgets on remote changes
- Graceful fallback to local-only storage if CloudKit initialization fails

### Notifications (UNUserNotifications)
- Permission requested on first launch via AppDelegate
- **5 preset rules:** At deadline, 5m before, 15m before, 1h before, 1 day before
- Multi-select toggles per countdown
- Identifier format: `countdown-{countdownUUID}-{ruleUUID}` for targeted cancellation
- Rescheduled on edit, cancelled on delete
- Reconciled on app launch (rebuilds all pending notifications)
- Shows as banner + sound even when app is in foreground

### Widgets (WidgetKit)
- **Single Countdown widget:** Small only. Live-updating timer (`Text(deadline, style: .timer)`), centered title, clock-style display.
- **Multi Countdown widget:** Small (up to 4, 2x2 grid blocks), Medium (up to 5, row list with callout font). Sorted by pinned first, then priority rank.
- Data shared via `WidgetDataBridge` → App Group UserDefaults (JSON-encoded snapshots)
- Timeline: entries every 15 minutes for 4 hours ahead, policy `.atEnd`
- `WidgetCenter.shared.reloadAllTimelines()` called after every CRUD operation and iCloud sync
- Empty state shows "No Countdowns — Add one in the app"

### Widget Deep Linking
- URL scheme: `countdownpromax://`
- Single widget: `widgetURL(countdownpromax://open?id=<UUID>)` — whole widget taps to that countdown
- Multi widget: `Link(destination:)` per row — each countdown taps to its own detail
- App handles URL via `.onOpenURL`: activates window and posts navigation notification

### Floating Panel (macOS NSPanel)
- **NSPanel subclass:** Non-activating (doesn't steal focus), utility window style
- **Modes:** Always on Top (`.floating` level), Normal (`.normal` level), Hidden
- **Behavior:** Joins all Spaces, fullscreen auxiliary, movable by background, transparent titlebar
- **Content:** SwiftUI hosted via NSHostingView, shows up to 6 countdowns (pinned first, then by priority rank)
- **Persistence:** Panel mode and frame position saved to UserDefaults, restored on next show
- **Menu access:** Panel menu → Toggle (Cmd+Shift+P), Always on Top, Normal Window

### Menu Bar Commands
- **Cmd+N:** New Countdown (opens create sheet)
- **Cmd+Shift+P:** Toggle Floating Panel
- **Cmd+Shift+C:** Copy Top 6 Summaries to clipboard
- **Panel → Always on Top:** Sets floating level
- **Panel → Normal Window:** Sets normal level
- **Share → Copy Top 6 Summaries:** Copies pinned-first, priority-ranked summaries

### Deadline Semantics (Time Zone / AoE Support)
- **Three semantics:** Local (default), Specific Time Zone, Anywhere on Earth (AoE)
- **DeadlineSemanticsSection** in edit sheet: segmented picker for Local/Time Zone/AoE
- **Time zone picker:** 8 common zones (US Eastern, Pacific, Central, UTC, UK, Central Europe, Japan, China) plus all system time zones
- **Local conversion display:** When non-local semantics selected, shows both "Original: <date> AoE" and "Your local time: <date>" in the edit sheet
- **Card badge:** Small capsule badge (e.g., "AoE", "EST", "PST") next to title in CountdownCardView
- **Floating panel badge:** Timezone abbreviation shown next to countdown text
- **Widget badge:** Timezone badge shown in both single and multi widget views
- **AoE implementation:** UTC-12 (Baker Island time) — the last timezone on Earth. Stored as `deadlineSemanticsRaw = "aoe"` with no explicit timezone ID
- **DST-safe:** Uses Apple's `TimeZone` APIs for all conversions
- **CloudKit-compatible:** Stored as raw strings (`deadlineSemanticsRaw`, `deadlineTimeZoneID`)

### Milestones
- **Milestone model:** `Milestone` struct (Codable, Identifiable) with id, title, date, isDone
- **Storage:** JSON-encoded `[Milestone]` in `Countdown.milestonesData` (same pattern as notificationRules)
- **CRUD in edit sheet:** MilestonesSection with:
  - Add milestone via title text field + date picker + add button
  - Quick-add presets: "Draft done", "Experiments", "Figures", "Camera-ready"
  - Toggle done/undone (checkmark circle)
  - Delete individual milestones (x button)
  - Shows time left or "overdue" per milestone
- **Next milestone display:**
  - CountdownCardView shows "Next: <title>" with flag icon for the earliest undone future milestone
  - If an undone milestone is overdue, shows "Overdue: <title>" with warning icon in red
  - FloatingPanelContentView shows "▸ <title>" in orange below countdown title
- **Widget support:**
  - `CountdownSnapshot` includes `nextMilestoneTitle` and `nextMilestoneDate`
  - Single widget (medium/large) shows "Next: <title>" with flag icon
  - Multi widget (large only) shows milestone subtitle per countdown row
- **Sorted by date:** Milestones auto-sort chronologically when added
- **CloudKit-compatible:** Stored as Data blob, syncs automatically

### Quick Share (Clipboard Copy)
- **Single countdown copy format:**
  - Local: `"Title: 3d 4h left (deadline: Aug 15, 11:59 PM)"`
  - AoE/TimeZone: `"Title: 3d 4h left (deadline: Aug 15, 11:59 PM AoE · Aug 15, 8:59 PM PDT)"`
- **Multi countdown copy format:** Bullet list of top 6 (pinned first, soonest), e.g.:
  - `"• Title: 3d 4h left (deadline: Aug 15, 11:59 PM AoE · Aug 15, 8:59 PM PDT)"`
- **Entry points:**
  - Context menu → "Copy Summary" on each countdown card in list view
  - Context menu → "Copy Summary" on each row in floating panel
  - App menu → Share → "Copy Top 6 Summaries" (Cmd+Shift+C)
- **Feedback:** Green checkmark "Copied to clipboard" toast at top of window, auto-dismisses after 2 seconds
- **Implementation:** `CountdownFormatter.shareSummary(for:)` methods, `NSPasteboard.general`

### One-Time Widget Setup Prompt
- After creating the first countdown, a material-style banner slides up:
  > "Add a Widget to Your Desktop — Right-click your desktop, select 'Edit Widgets...', then search for 'Countdown' to add it."
- Dismissed with "Got it" button, never shown again (`@AppStorage`)

---

## Configuration Constants

| Constant | Value |
|----------|-------|
| App Group ID | `group.sz904.CountDown-ProMax` |
| CloudKit Container | `iCloud.sz904.CountDown-ProMax` |
| URL Scheme | `countdownpromax` |
| Single Widget Kind | `SingleCountdownWidget` |
| Multi Widget Kind | `MultiCountdownWidget` |
| Ending Soon Threshold | 72 hours |
| Default Deadline | Next full hour from now |
| Widget Refresh Interval | 15 minutes |
| LiveCountdown Fast Update | 1 second (< 5 min or overdue) |
| LiveCountdown Normal Update | 10 seconds |
| Max Floating Panel Items | 6 |
| Max Widget Items (large) | 6 |
| Max Widget Items (medium) | 5 |

---

## Entitlements

### Main App (CountDown_ProMax.entitlements)
- `com.apple.developer.icloud-container-identifiers`: iCloud.sz904.CountDown-ProMax
- `com.apple.developer.icloud-services`: CloudKit
- `com.apple.security.application-groups`: group.sz904.CountDown-ProMax
- `aps-environment`: development
- `com.apple.developer.aps-environment`: development

### Widget Extension (CountDown_ProMax_WidgetsExtension.entitlements)
- Same iCloud container, App Group, and push notification entitlements

---

## Key Architectural Patterns

1. **Enums as raw strings** in @Model for CloudKit compatibility; computed properties for type-safe access
2. **JSON Data blobs** for complex nested data (NotificationRules, Milestones) — avoids CloudKit relationship issues
3. **TimelineView** for all live countdown displays (no Timer, no Combine)
4. **@Observable** for managers (no ObservableObject/Combine)
5. **MainActor default isolation** (Swift 6); `nonisolated` or `@Sendable` where needed
6. **App Group shared SQLite** for widget data access; main app syncs via CloudKit, widget reads only
7. **Snapshot bridge** (lightweight Codable structs) for fast widget data via UserDefaults; includes summary fields for milestones
8. **Graceful fallback** to local-only storage if CloudKit container fails at startup
9. **AoE as UTC-12** — deterministic timezone for Anywhere-on-Earth semantics; stored as enum raw string, not timezone ID
10. **orderIndex as priority rank** — drag-to-reorder sets `orderIndex`; widgets, floating panel, and copy summaries all sort by pinned-first then orderIndex. One-time migration assigns initial values from soonest-deadline order.

---

## Post-MVP Roadmap (v1.3+)

### High Priority
- iOS/iPadOS companion app (shared models, SwiftUI multiplatform)
- Menu bar glance view + quick add
- Conference template preset (auto-sets AoE + suggested notifications)
- Focus filters (show certain countdowns per Focus mode)
- Tags and search
- Searchable time zone picker

### Later
- Overdue repeat reminders (hourly/daily)
- CloudKit sharing/collaboration
- Siri / App Intents automation
- Auto mode for floating panel (context—aware z-order)
- Milestone notifications (separate from countdown notifications)


