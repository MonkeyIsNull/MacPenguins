#!/usr/bin/env swift

import Foundation
import AppKit

print("🐧 MacPenguins Quick Demo - Penguins that Actually Work!")

// Simple penguin that definitely lands on windows
class WorkingPenguin {
    var window: NSWindow
    var penguinView: NSView
    var position = CGPoint(x: 200, y: 100)
    var velocity = CGPoint(x: 2, y: 0)
    var falling = true
    var windowTops: [CGFloat] = []

    init() {
        // Create a simple overlay window
        let screen = NSScreen.main!
        window = NSWindow(
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

        // Create penguin view (bright red square)
        penguinView = NSView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        penguinView.wantsLayer = true
        penguinView.layer?.backgroundColor = NSColor.red.cgColor
        penguinView.layer?.borderColor = NSColor.black.cgColor
        penguinView.layer?.borderWidth = 2

        window.contentView?.addSubview(penguinView)

        // Get window tops for collision
        getWindowTops()

        print("✅ Created penguin window overlay")
        print("🎯 Found \(windowTops.count) window tops for landing")
        print("📺 Screen height: \(screen.frame.height)")
    }

    func getWindowTops() {
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]

        guard let windows = windowList else { return }

        let screen = NSScreen.main!

        for windowDict in windows {
            guard let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else { continue }

            var bounds = CGRect.zero
            CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds)

            let isOnScreen = windowDict[kCGWindowIsOnscreen as String] as? Bool ?? false
            let level = windowDict[kCGWindowLayer as String] as? Int ?? 0

            // Only windows on main screen that are reasonable size
            if isOnScreen &&
               bounds.width > 100 && bounds.height > 50 &&
               level >= 0 && level < 20 &&
               bounds.intersects(screen.frame) {

                // Convert to our coordinate system (Y=0 at top of screen)
                let windowTop = screen.frame.height - bounds.maxY
                windowTops.append(windowTop)
            }
        }

        windowTops.sort()
        print("🏠 Window tops at Y: \(windowTops.prefix(5).map { Int($0) })")
    }

    func update() {
        if falling {
            // Apply gravity
            velocity.y += 0.8

            // Move penguin
            position.y += velocity.y

            // Check if we hit a window top
            for windowTop in windowTops {
                if position.y > windowTop && position.y - velocity.y <= windowTop {
                    position.y = windowTop
                    velocity.y = 0
                    falling = false
                    velocity.x = 2 // Start walking
                    print("🐧 Penguin landed on window at Y=\(Int(windowTop))!")
                    break
                }
            }

            // Check if hit bottom of screen
            let screenHeight = NSScreen.main!.frame.height
            if position.y > screenHeight - 30 {
                position.y = screenHeight - 30
                velocity.y = 0
                falling = false
                velocity.x = 2
                print("🐧 Penguin hit ground!")
            }
        } else {
            // Walking on surface
            position.x += velocity.x

            // Wrap around screen
            if position.x > NSScreen.main!.frame.width {
                position.x = 0
            }
        }

        // Update view position
        penguinView.frame.origin = position
    }

    func run() {
        print("🎬 Starting penguin animation...")
        print("👀 Watch your screen - red square should fall and land on window!")

        // Animation loop
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            self.update()
        }

        // Run for 30 seconds
        RunLoop.current.run(until: Date().addingTimeInterval(30))
        timer.invalidate()
        window.close()
    }
}

// Create and run the demo
let demo = WorkingPenguin()
demo.run()

print("🏁 Demo finished!")