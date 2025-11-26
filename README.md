# MacPenguins

A modern macOS port of the classic xpenguins desktop application. Watch animated penguins walk across your windows and desktop, bringing charm and whimsy to your Mac.

## Overview

MacPenguins is a background service that displays animated cartoon penguins that appear to walk on top of windows and interact with your desktop environment. The penguins can walk along window tops, fall from the sky, climb window edges, and perform various actions like reading or sleeping.

This is a complete rewrite of the original X11-based xpenguins using modern macOS technologies:
- **Swift/Objective-C** for native macOS performance
- **Core Animation** for smooth, hardware-accelerated graphics
- **CGWindow API** for window detection and collision
- **Spaces Support** for multiple desktop compatibility
- **Multiple Display Support** for modern multi-monitor setups

## Features

### Core Functionality
- Animated penguins that walk on window tops and screen edges
- Physics simulation with gravity, collision detection, and realistic movement
- Multiple penguin states: walking, running, falling, climbing, floating, and various actions
- Window association - penguins follow windows when they move
- Smooth transitions between desktop spaces
- Multiple display support with seamless penguin movement

### Modern macOS Integration
- **Background Service** - runs invisibly without dock icon
- **Notch Support** - penguins walk around MacBook Pro notch areas
- **Full Screen Handling** - smart behavior during full-screen applications
- **Stage Manager Compatible** - works with macOS window management
- **Energy Efficient** - optimized for Apple Silicon performance

### Penguin Behavior
- **12 Different States**: Walker, Faller, Tumbler, Floater, Climber, Runner, and more
- **Interactive Elements**: Click on penguins to "zap" them
- **Death and Rebirth**: Penguins can be squashed, splatted, or zapped, then ascend as angels
- **Action States**: Penguins occasionally stop to read books or take naps
- **Customizable Themes**: Support for different penguin types and sprites

## System Requirements

- macOS 15.0 or later
- Apple Silicon (M1/M2/M3) or Intel Mac
- No special permissions required (uses standard CGWindow API)

## Installation

### From Xcode
1. Open `MacPenguins.xcodeproj` in Xcode
2. Build and run the project
3. The app will start as a background service

### Manual Build
```bash
# Clone or download the project
cd MacPenguins

# Build with Xcode command line tools (if available)
xcodebuild -project MacPenguins.xcodeproj -scheme MacPenguins -configuration Release build

# Or compile individual components for testing
swiftc -parse-as-library -typecheck MacPenguins/Sources/*.swift
```

## Usage

### Basic Operation
Once launched, MacPenguins runs as a background service. Penguins will automatically spawn and begin walking on your windows.

**Default Configuration:**
- 10 penguins
- "Penguins" theme with normal and skateboarder types
- 60ms animation delay (smooth 60 FPS equivalent)

### Themes
MacPenguins includes the converted "Penguins" theme from the original xpenguins. Theme assets are located in:
```
MacPenguins/Themes/Penguins/
├── config                      # Theme configuration
├── normal_walker_right.png     # Walking animation
├── normal_faller.png           # Falling animation
├── normal_tumbler.png          # Tumbling animation
├── normal_climber.png          # Climbing animation
├── normal_floater.png          # Floating animation
├── normal_explosion.png        # Death animation
├── normal_angel.png            # Ascension animation
├── normal_reader.png           # Reading action
├── normal_splatted.png         # Splat death
└── skateboarder_*.png          # Skateboarder penguin variants
```

### Penguin States Explained
- **Walker/Runner**: Normal walking behavior along window tops
- **Faller**: Penguin dropping from top of screen
- **Tumbler**: Falling after dropping off a window edge
- **Floater**: Flying/floating movement with gentle physics
- **Climber**: Scaling window sides or screen edges
- **Action States**: Reading, sleeping, or other idle behaviors
- **Death States**: Explosion, splat, squash, or zap animations
- **Angel**: Ascending to heaven before respawning

## Architecture

### Core Components
- **MacPenguinsService**: Main service coordinator
- **PenguinEngine**: Penguin behavior and physics simulation
- **WindowManager**: CGWindow-based window detection and Spaces support
- **AnimationRenderer**: Core Animation rendering with overlay windows
- **CollisionDetector**: Window collision and surface detection
- **ThemeManager**: Theme loading and sprite management
- **Penguin**: Individual penguin state machine and physics

### Technical Details
- **Window Detection**: Uses CGWindowListCopyWindowInfo for comprehensive window enumeration
- **Spaces Support**: Private APIs for multi-desktop compatibility
- **Physics Engine**: Custom implementation with gravity, collision response, and momentum
- **Rendering**: CALayer-based system with transparent overlay windows
- **Performance**: 60 FPS update loop with efficient collision detection

## Development

### Project Structure
```
MacPenguins/
├── MacPenguins.xcodeproj/       # Xcode project file
├── MacPenguins/
│   ├── Sources/                 # Swift/Objective-C source code
│   │   ├── AppDelegate.swift    # Main application entry
│   │   ├── MacPenguinsService.swift
│   │   ├── PenguinEngine.swift
│   │   ├── Penguin.swift
│   │   ├── WindowManager.swift
│   │   ├── AnimationRenderer.swift
│   │   ├── CollisionDetector.swift
│   │   ├── ThemeManager.swift
│   │   ├── WindowDetector.h/.m  # Objective-C window detection
│   │   └── MacPenguins-Bridging-Header.h
│   ├── Assets.xcassets/         # App icons and assets
│   ├── Themes/                  # Penguin sprite themes
│   ├── Info.plist              # App configuration
│   └── MacPenguins.entitlements
├── xpenguins-2.2/              # Original xpenguins source (reference)
└── README.md
```

### Building from Source
1. Ensure you have Xcode or Xcode Command Line Tools installed
2. Open the project in Xcode or build via command line
3. The app is configured as a background service (LSUIElement = YES)
4. No special code signing or entitlements required for basic functionality

### Extending MacPenguins
- **New Themes**: Add PNG sprites to `MacPenguins/Themes/[ThemeName]/`
- **Custom Behaviors**: Modify `PenguinEngine.swift` for new penguin actions
- **Advanced Window Detection**: Enhance `WindowDetector.m` for special window types
- **Visual Effects**: Extend `AnimationRenderer.swift` for additional graphics

## Compatibility

### Supported macOS Features
- ✅ Multiple Spaces (Mission Control)
- ✅ Multiple Displays
- ✅ MacBook Pro Notch
- ✅ Full Screen Applications
- ✅ Stage Manager
- ✅ Dark Mode (transparent overlays)
- ✅ Apple Silicon optimization

### Limitations
- Requires macOS 15.0+ for best compatibility
- Uses private APIs for Spaces support (may need updates for future macOS versions)
- Some window managers may not be fully supported

## Credits

### Original xpenguins
Created by Robin Hogan and contributors. The original X11-based xpenguins inspired this modern macOS port.

### MacPenguins
Modern macOS implementation focusing on native performance and contemporary desktop integration.

## License

This project maintains compatibility with the original xpenguins licensing while providing a fresh implementation for modern macOS systems.

---

Enjoy watching penguins walk across your Mac! 🐧