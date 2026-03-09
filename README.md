# NotchDock

Turn your MacBook Pro notch into an interactive app dock. Pin your favorite apps and launch them right from the notch area.

## Features

- **Hover to expand** — the dock hides behind the notch and reveals pinned apps on hover
- **Click to launch** — open apps with a single click without stealing focus from the current window
- **Drag to reorder** — rearrange app icons by dragging them into position
- **Swipe to remove** — swipe an icon up to unpin it from the dock
- **Running indicators** — small dot below each app that is currently running
- **Shiny border** — animated gradient shimmer around the dock
- **Menu bar settings** — add/remove apps and manage the dock from the menu bar

## Requirements

- macOS 13.0+
- MacBook Pro with notch (works on non-notch Macs with a fallback region)

## Build & Run

```bash
xcodebuild -project NotchDock.xcodeproj -scheme NotchDock build
```

Or open `NotchDock.xcodeproj` in Xcode and hit Run.

## How It Works

The app places a transparent, non-activating panel over the notch. When you hover over it, the panel expands into a T-shaped dock showing your pinned apps. Moving the mouse away collapses it back. Apps are persisted via UserDefaults and default to Finder, Safari, Mail, and Messages on first launch.

## Architecture

```
NotchDock/
├── NotchDockApp.swift          # Entry point, menu bar extra
├── Models/
│   ├── DockApp.swift           # App model (bundle ID, name)
│   └── DockStore.swift         # State management, persistence
├── Window/
│   ├── NotchWindow.swift       # Custom NSPanel
│   └── NotchWindowController.swift  # Expand/collapse, hover, masking
├── Views/
│   ├── NotchDockView.swift     # Main dock UI, drag-and-drop
│   ├── AppIconView.swift       # Icon, hover, swipe-to-remove
│   └── SettingsView.swift      # Menu bar settings
└── Utilities/
    ├── AppLauncher.swift       # Launch apps, get icons, check running
    └── NotchDetector.swift     # Detect notch rect on screen
```

Built with Swift, SwiftUI, AppKit, and Combine.
