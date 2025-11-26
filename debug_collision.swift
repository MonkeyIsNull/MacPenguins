#!/usr/bin/env swift

import Foundation
import CoreGraphics
import AppKit

// Test collision detection logic
print("🔍 Testing Collision Detection...")

// Get some real windows
let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]

if let windows = windowList {
    var testWindows: [CGRect] = []

    for windowDict in windows {
        guard let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else { continue }

        var bounds = CGRect.zero
        CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds)

        let isOnScreen = windowDict[kCGWindowIsOnscreen as String] as? Bool ?? false
        let level = windowDict[kCGWindowLayer as String] as? Int ?? 0

        if isOnScreen && bounds.width > 100 && bounds.height > 50 && level >= 0 && level < 20 {
            testWindows.append(bounds)
            if testWindows.count >= 3 { break } // Just test with 3 windows
        }
    }

    print("📊 Testing with \(testWindows.count) windows:")
    for (i, window) in testWindows.enumerated() {
        print("  Window \(i+1): \(window)")
    }

    // Test penguin falling onto window
    if let firstWindow = testWindows.first {
        let windowTop = firstWindow.minY // In macOS coordinates, this is the TOP of the window
        let penguinSize = CGSize(width: 32, height: 32)

        // Test penguin falling from above the window
        let penguinX = firstWindow.midX
        let penguinY = windowTop - 10 // Just above window top

        let penguinRect = CGRect(
            x: penguinX - penguinSize.width/2,
            y: penguinY - penguinSize.height/2,
            width: penguinSize.width,
            height: penguinSize.height
        )

        print("\n🐧 Testing penguin collision:")
        print("  Window bounds: \(firstWindow)")
        print("  Window top Y: \(windowTop)")
        print("  Penguin rect: \(penguinRect)")
        print("  Penguin intersects window: \(penguinRect.intersects(firstWindow))")
        print("  Distance to window top: \(penguinY - windowTop)")

        // Test if penguin should land on window
        if penguinRect.intersects(firstWindow) {
            print("  ✅ Penguin should land on window!")
            print("  Landing Y should be: \(windowTop - penguinSize.height/2)")
        } else {
            print("  ❌ No collision detected")
        }
    }
}