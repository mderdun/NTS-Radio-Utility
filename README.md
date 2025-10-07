# NTS Radio Menu Bar Utility

A clean, Mac-native menu bar app for listening to NTS Radio.

## Features

- 🎵 Stream NTS Radio 1 and NTS 2
- 🖼️ Current show information with cover art
- 🎛️ Native macOS controls (Picker and Slider)
- 🔊 Independent volume control for radio stream
- ⏯️ Simple play/pause control
- 📡 Auto-refreshing show information
- ⏭️ "Next up" show preview

## Setup Instructions

### 1. Configure Menu Bar Only Mode

To make the app appear only in the menu bar (not in the Dock):

1. Open the project in Xcode
2. Select the project in the navigator
3. Select the "NTS Radio Utility" target
4. Go to the "Info" tab
5. Add a new property:
   - Key: `Application is agent (UIElement)` (or `LSUIElement`)
   - Type: Boolean
   - Value: YES

### 2. Build and Run

1. Select your Mac as the build target
2. Build and run the project (⌘R)
3. The app will appear in your menu bar as "NTS1" or "NTS2"
4. Click the menu bar item to access controls

## How to Use

1. **Click the menu bar icon** to open the control panel
2. **Switch stations** using the picker menu (NTS 1 / NTS 2)
3. **Adjust volume** by dragging the slider
4. **Play/Pause** using the button
5. **View show information** including title, location, times, and cover art
6. **See what's next** in the bottom bar

## Architecture

```
NTS Radio Utility/
├── Models/              # Data models for API responses
├── Services/            # Audio playback and API services
├── ViewModels/          # State management
└── Views/               # SwiftUI views
    ├── MenuBarView      # Menu bar icon view
    └── PopoverView      # Main control panel (horizontal layout)
```

## API

The app uses the NTS Radio public API:
- Live data: `https://www.nts.live/api/v2/live`
- Stream URLs:
  - NTS 1: `https://streams.radiomast.io/nts1`
  - NTS 2: `https://streams.radiomast.io/nts2`

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Notes

- Show information refreshes automatically every 60 seconds
- Volume control is independent of system volume
- The app requires an internet connection to stream and fetch show data
