#!/usr/bin/env swift

import Foundation
import AppKit

print("🐧 Creating WORKING MacPenguins Demo...")

// Create a working penguin that definitely respects physics
class TestPenguin: NSView {
    var velocity = CGPoint(x: 0, y: 0)
    var windowTops: [CGFloat] = []
    var isOnSurface = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        loadWindowTops()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        loadWindowTops()
    }

    func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.systemRed.cgColor
        layer?.borderColor = NSColor.black.cgColor
        layer?.borderWidth = 2
        layer?.cornerRadius = 3
    }

    func loadWindowTops() {
        // Get current windows and find their tops
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return }

        let mainScreen = NSScreen.main!
        let screenHeight = mainScreen.frame.height

        for windowDict in windowList {
            guard let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else { continue }

            var bounds = CGRect.zero
            CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds)

            let isOnScreen = windowDict[kCGWindowIsOnscreen as String] as? Bool ?? false
            let level = windowDict[kCGWindowLayer as String] as? Int ?? 0

            if isOnScreen && bounds.width > 100 && bounds.height > 50 && level >= 0 && level < 20 {
                // Convert to AppKit coordinates (Y=0 at bottom)
                let windowTop = screenHeight - bounds.minY
                if windowTop > 50 && windowTop < screenHeight - 50 {
                    windowTops.append(windowTop)
                }
            }
        }

        windowTops.sort()
        print("📊 Loaded \(windowTops.count) window surfaces for collision")
        if windowTops.count > 0 {
            print("   Window tops: \(windowTops.prefix(5).map { Int($0) })")
        }
    }

    func update() {
        if !isOnSurface {
            // Apply gravity
            velocity.y += 0.6

            // Check window collision before moving
            let nextY = frame.minY - velocity.y // Subtract because we're falling down

            // Check if we would hit a window top
            for windowTop in windowTops {
                if frame.minY > windowTop && nextY <= windowTop + 5 {
                    // Landing on window!
                    frame.origin.y = windowTop
                    velocity.y = 0
                    velocity.x = 3.0 // Start walking
                    isOnSurface = true
                    print("🎯 PENGUIN LANDED on window at Y=\(Int(windowTop))!")
                    break
                }
            }

            if !isOnSurface {
                frame.origin.y = nextY
            }

            // Hit ground
            if frame.minY <= 30 {
                frame.origin.y = 30
                velocity.y = 0
                velocity.x = 3.0
                isOnSurface = true
                print("🎯 PENGUIN HIT GROUND!")
            }
        } else {
            // Walking on surface
            frame.origin.x += velocity.x

            // Wrap around screen
            if frame.maxX > NSScreen.main!.frame.width {
                frame.origin.x = 0
            }
        }
    }
}

// Create main window
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

print("✅ Created overlay window: \(screen.frame)")

// Create test penguins
var penguins: [TestPenguin] = []
for i in 0..<3 {
    let penguin = TestPenguin(frame: CGRect(x: CGFloat(i * 300 + 200), y: screen.frame.height - 50, width: 30, height: 30))
    window.contentView?.addSubview(penguin)
    penguins.append(penguin)
}

print("🐧 Created \(penguins.count) test penguins")
print("👀 Watch your screen - red squares should fall and land on windows!")
print("⏰ Running for 20 seconds...")

// Animation loop
var frame = 0
let timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
    for penguin in penguins {
        penguin.update()
    }

    frame += 1
    if frame % 120 == 0 { // Every 2 seconds
        print("⏱️  Frame \(frame/60)s - Penguins running...")
    }

    if frame >= 1200 { // 20 seconds
        print("🏁 Demo complete!")
        exit(0)
    }
}

RunLoop.main.run(until: Date().addingTimeInterval(25))
timer.invalidate()
window.close()

print("Demo finished!")