#!/usr/bin/env swift

import Foundation
import AppKit

print("🐧 Physics Demo - Penguins with Proper Edge Detection")

struct WindowSurface {
    let left: CGFloat
    let right: CGFloat
    let top: CGFloat

    func contains(x: CGFloat) -> Bool {
        return x >= left && x <= right
    }
}

class PhysicsPenguin: NSView {
    var velocity = CGPoint(x: 0, y: 0)
    var windowSurfaces: [WindowSurface] = []
    var currentSurface: WindowSurface?
    var state: String = "falling"

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        loadWindowSurfaces()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        loadWindowSurfaces()
    }

    func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.systemBlue.cgColor
        layer?.borderColor = NSColor.white.cgColor
        layer?.borderWidth = 2
        layer?.cornerRadius = 4
    }

    func loadWindowSurfaces() {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return }

        let mainScreen = NSScreen.main!
        let screenHeight = mainScreen.frame.height

        for windowDict in windowList {
            guard let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else { continue }

            var bounds = CGRect.zero
            CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds)

            let isOnScreen = windowDict[kCGWindowIsOnscreen as String] as? Bool ?? false
            let level = windowDict[kCGWindowLayer as String] as? Int ?? 0

            if isOnScreen && bounds.width > 50 && bounds.height > 30 && level >= 0 && level < 20 {
                // Convert to AppKit coordinates and create surface
                let surface = WindowSurface(
                    left: bounds.minX,
                    right: bounds.maxX,
                    top: screenHeight - bounds.minY
                )

                if surface.top > 50 && surface.top < screenHeight - 50 {
                    windowSurfaces.append(surface)
                }
            }
        }

        windowSurfaces.sort { $0.top < $1.top }
        print("🏠 Loaded \(windowSurfaces.count) window surfaces")
        for (i, surface) in windowSurfaces.prefix(3).enumerated() {
            print("   Surface \(i+1): X=\(Int(surface.left))-\(Int(surface.right)), Y=\(Int(surface.top))")
        }
    }

    func update() {
        switch state {
        case "falling":
            // Apply gravity
            velocity.y += 0.8
            let nextY = frame.minY - velocity.y

            // Check for window collision
            for surface in windowSurfaces {
                if frame.midX >= surface.left && frame.midX <= surface.right &&
                   frame.minY > surface.top && nextY <= surface.top + 5 {
                    // Land on this surface
                    frame.origin.y = surface.top
                    velocity.y = 0
                    velocity.x = 4.0
                    currentSurface = surface
                    state = "walking"
                    print("🎯 Penguin landed on surface: X=\(Int(surface.left))-\(Int(surface.right))")
                    break
                }
            }

            if state == "falling" {
                frame.origin.y = nextY
            }

            // Ground collision
            if frame.minY <= 20 {
                frame.origin.y = 20
                velocity.y = 0
                velocity.x = 4.0
                currentSurface = WindowSurface(left: 0, right: NSScreen.main!.frame.width, top: 20)
                state = "walking"
                print("🎯 Penguin hit ground")
            }

        case "walking":
            guard let surface = currentSurface else {
                state = "falling"
                return
            }

            // Move horizontally
            frame.origin.x += velocity.x

            // Check if we've walked off the edge
            if frame.midX < surface.left || frame.midX > surface.right {
                state = "falling"
                currentSurface = nil
                velocity.x *= 0.5 // Keep some horizontal velocity
                print("💨 Penguin fell off edge at X=\(Int(frame.midX))")
            }

            // Wrap around screen horizontally if on ground
            if surface.top <= 25 && frame.maxX > NSScreen.main!.frame.width {
                frame.origin.x = 0
            }

        default:
            break
        }

        // Update visual state
        switch state {
        case "falling":
            layer?.backgroundColor = NSColor.systemRed.cgColor
        case "walking":
            layer?.backgroundColor = NSColor.systemBlue.cgColor
        default:
            layer?.backgroundColor = NSColor.systemGray.cgColor
        }
    }
}

// Setup
let screen = NSScreen.main!
let window = NSWindow(
    contentRect: screen.frame,
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)

window.level = NSWindow.Level.floating
window.backgroundColor = NSColor.clear
window.isOpaque = false
window.ignoresMouseEvents = true
window.makeKeyAndOrderFront(nil)

// Create test penguins at different positions
var penguins: [PhysicsPenguin] = []
let positions = [200, 500, 800]
for (i, x) in positions.enumerated() {
    let penguin = PhysicsPenguin(frame: CGRect(x: CGFloat(x), y: screen.frame.height - 50, width: 30, height: 30))
    window.contentView?.addSubview(penguin)
    penguins.append(penguin)
}

print("🎬 Starting physics demo...")
print("   RED = Falling, BLUE = Walking")
print("   Watch them fall → land → walk → fall off edges!")

// Animation loop
var frameCount = 0
let timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
    for penguin in penguins {
        penguin.update()
    }

    frameCount += 1
    if frameCount % 180 == 0 { // Every 3 seconds
        let states = penguins.map { $0.state }
        print("⏱️  \(frameCount/60)s - States: \(states)")
    }

    if frameCount >= 1800 { // 30 seconds
        print("🏁 Physics demo complete!")
        exit(0)
    }
}

RunLoop.main.run(until: Date().addingTimeInterval(35))
timer.invalidate()
window.close()