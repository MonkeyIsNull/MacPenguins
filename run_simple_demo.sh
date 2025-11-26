#!/bin/bash
#
# Simple MacPenguins Demo - Single Screen, Fixed Coordinates
#

echo "🐧 MacPenguins Simple Demo"
echo "Starting penguins on your main screen only..."

# Create a simplified version that works on main screen only
cat > simple_demo.swift << 'EOF'
#!/usr/bin/env swift

import Foundation
import AppKit

class SimplePenguin {
    var position: CGPoint
    var velocity: CGPoint = CGPoint(x: 2, y: 0)
    var onGround = false

    init(x: CGFloat, y: CGFloat) {
        self.position = CGPoint(x: x, y: y)
    }

    func update(windowTops: [CGFloat], screenHeight: CGFloat) {
        position.x += velocity.x

        if !onGround {
            velocity.y += 0.5 // gravity
            position.y += velocity.y

            // Check if landed on window
            for windowTop in windowTops {
                if abs(position.y - windowTop) < 10 && position.y > windowTop - 5 {
                    position.y = windowTop
                    velocity.y = 0
                    onGround = true
                    print("🐧 Penguin landed on window at Y=\(windowTop)")
                    break
                }
            }

            // Check if hit ground
            if position.y >= screenHeight - 20 {
                position.y = screenHeight - 20
                velocity.y = 0
                onGround = true
                print("🐧 Penguin landed on ground")
            }
        }

        // Wrap around screen
        if position.x > 1440 {
            position.x = 0
        }
    }
}

// Get main screen
let mainScreen = NSScreen.main!
let screenRect = mainScreen.frame
print("Main screen: \(screenRect)")

// Get windows on main screen
let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
var windowTops: [CGFloat] = []

if let windows = windowList {
    for windowDict in windows {
        guard let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else { continue }
        var bounds = CGRect.zero
        CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds)

        let isOnScreen = windowDict[kCGWindowIsOnscreen as String] as? Bool ?? false
        let level = windowDict[kCGWindowLayer as String] as? Int ?? 0

        // Only windows on main screen
        if isOnScreen && bounds.width > 100 && bounds.height > 50 && level >= 0 && level < 20 &&
           bounds.minX >= screenRect.minX && bounds.maxX <= screenRect.maxX {
            windowTops.append(bounds.minY)
        }
    }
}

windowTops.sort()
print("Found \(windowTops.count) window tops: \(windowTops.prefix(5))")

// Create penguins
var penguins = [SimplePenguin]()
for i in 0..<3 {
    let penguin = SimplePenguin(x: CGFloat(i * 200 + 100), y: 0)
    penguins.append(penguin)
}

print("Starting \(penguins.count) penguins...")
print("Watch your main screen - penguins should fall and land on windows!")
print("Press Ctrl+C to stop")

// Simple animation loop
var frame = 0
while frame < 3000 { // Run for ~50 seconds at 60fps
    for penguin in penguins {
        penguin.update(windowTops: windowTops, screenHeight: screenRect.height)
    }

    if frame % 60 == 0 {
        print("Frame \(frame/60)s: Penguins at \(penguins.map { Int($0.position.x) })")
    }

    usleep(16667) // ~60 fps
    frame += 1
}
EOF

swift simple_demo.swift