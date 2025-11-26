#!/usr/bin/env swift

import Foundation
import CoreGraphics
import AppKit

// Quick test to see if window detection works
let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]

if let windows = windowList {
    print("🪟 Found \(windows.count) total windows")

    var visibleWindows = 0
    for (index, windowDict) in windows.enumerated() {
        guard let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID,
              let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any] else {
            continue
        }

        var bounds = CGRect.zero
        CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds)

        let ownerName = windowDict[kCGWindowOwnerName as String] as? String ?? "Unknown"
        let windowName = windowDict[kCGWindowName as String] as? String ?? ""
        let isOnScreen = windowDict[kCGWindowIsOnscreen as String] as? Bool ?? false
        let level = windowDict[kCGWindowLayer as String] as? Int ?? 0

        // Filter for reasonable windows
        if isOnScreen &&
           bounds.width > 50 &&
           bounds.height > 50 &&
           level >= 0 && level < 20 {
            visibleWindows += 1
            if index < 5 { // Show first 5 windows
                print("  \(visibleWindows). \(ownerName): '\(windowName)' at \(bounds) level=\(level)")
            }
        }
    }

    print("✅ \(visibleWindows) visible windows suitable for penguin collision")
} else {
    print("❌ Failed to get window list")
}

print("\n🖥️ Screen bounds:")
for (index, screen) in NSScreen.screens.enumerated() {
    print("  Screen \(index + 1): \(screen.frame)")
}